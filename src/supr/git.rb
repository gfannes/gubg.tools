require('supr/cmd')
require('supr/log')

require('git')
require('pathname')

module Supr
    module Git
        def self.toplevel_dir(dir)
            dir = Supr::Cmd.run(%w[git rev-parse --show-superproject-working-tree], chomp: true)
            dir = Supr::Cmd.run(%w[git rev-parse --show-toplevel], chomp: true) if dir.empty?()
            dir
        end

        def self.submodules(dir)
            modules_fn = File.join(dir, '.gitmodules')
            os(3, "modules_fn: #{modules_fn}")

            if File.exist?(modules_fn)
                re = /^\s*path\s*=\s*(.+)$/
                File.read(modules_fn).split("\n").map do |line|
                    if md = re.match(line)
                        md[1]
                    end
                end.compact()
            else
                []
            end
        end

        def self.is_clean?(dir)
            git = ::Git.open(dir)
            git.status.changed.empty? && git.status.added.empty? && git.status.deleted.empty?# && git.status.untracked.empty?
        end

        class Repo
            attr_accessor(:rel)
            attr_accessor(:sha)
            attr_accessor(:subrepos)

            def initialize(rel: nil, sha: nil)
                @rel = rel
                @sha = sha
                @subrepos = []
            end

            def dir(base_dir)
                base_dir ? File.join(base_dir, @rel) : @rel
            end

            def has_subrepos?()
                !@subrepos.empty?()
            end
        end

        class State
            attr_accessor(:root)

            def initialize(toplevel_dir: nil)
                @root = nil
                @protected_branches = %w[master stable main develop]
                @toplevel_dir = toplevel_dir
            end

            def recurse(on_open: nil, on_close: nil)
                dir_stack = []

                my_recurse = ->(repo){
                    base_dir = dir_stack[-1] || @toplevel_dir

                    on_open.(repo, base_dir) if on_open

                    if repo.has_subrepos?()
                        dir_stack.push(repo.dir(base_dir))
                        repo.subrepos.each do |subrepo|
                            my_recurse.(subrepo)
                        end
                        dir_stack.pop()
                    end

                    on_close.(repo, base_dir) if on_close
                }
                my_recurse.(@root)
            end

            def run(*cmd)
                Dir.chdir(@toplevel_dir) do
                    Supr::Cmd.run(cmd, chomp: true) do |line|
                        puts(line)
                    end
                end
            end

            def push()
                recurse(on_open: ->(repo, base_dir){
                        git = ::Git.open(repo.dir(base_dir))
                        branch_name = git.lib.branch_current()
                        os(2, "Branch: #{branch_name}")

                        fail("I cannot force-push to branch '#{branch_name}'") if @protected_branches.include?(branch_name)

                        begin
                            git.lib.send(:command, 'push', '--set-upstream', 'origin', branch_name)
                        rescue ::Git::FailedError
                            error("Could not push '#{dir}' to branch '#{branch_name}'")
                        end
                    }
                )
            end

            def branch(branch_name)
                fail("I cannot create branches with name '#{branch_name}'") if @protected_branches.include?(branch_name)

                recurse(on_open: ->(repo, base_dir){
                        git = ::Git.open(repo.dir(base_dir))
                        if git.is_branch?(branch_name)
                            git.checkout(branch_name)
                            git.reset_hard(repo.sha)
                        else
                            git.lib.branch_new(branch_name)
                        end
                        git.checkout(branch_name)
                    }
                )
            end

            def apply(force: nil)
                git = ::Git.open(@toplevel_dir)
                git.fetch()

                recurse(on_open: ->(repo, base_dir){
                        dir = repo.dir(base_dir)
                        os(2, "Applying '#{dir}'")

                        if File.exists?(File.join(dir, '.git'))
                            os(2, ".git already present")
                        else
                            os(2, "Updating submod")
                            Supr::Cmd.run(%w[git -C]+[base_dir]+%w[submodule update --init]+[repo.rel])
                        end

                        git = ::Git.open(dir)
                        if !Supr::Git.is_clean?(dir)
                            git.reset_hard(repo.sha) if force
                            fail("Rep '#{dir}' is not clean") unless Supr::Git.is_clean?(dir)
                        end
                    }
                )
            end

            def from_dir()
                @root = Repo.new(rel: '', sha: ::Git.open(@toplevel_dir).log.first.sha)

                repo_stack = [@root]
                recurse = ->(base_dir){
                    Supr::Git.submodules(base_dir).each do |rel|
                        submod_dir = File.join(base_dir, rel)

                        repo = Repo.new(
                            rel: rel,
                            sha: ::Git.open(submod_dir).log.first.sha,
                        )
                        repo_stack[-1].subrepos << repo
            
                        repo_stack.push(repo)
                        recurse.(submod_dir)
                        repo_stack.pop()
                    end
                }
                recurse.(@toplevel_dir)

                self
            end

            def from_naft(str)
                # @todo: Use real naft parsing

                re_open = /{/
                re_close = /}/
                re_repo = /\[Repo\]\(rel:([^)]*)\)\(sha:([\da-f]*)\)/

                stack = [Repo.new()]

                str.each_line do |line|
                    puts(line)
                    if md = re_repo.match(line)
                        repo = Repo.new(rel: md[1], sha: md[2])
                        stack[-1].subrepos << repo
                    elsif re_open.match(line)
                        stack << stack[-1].subrepos[-1]
                    elsif re_close.match(line)
                        stack.pop
                    end
                end

                fail("Expected one element on the stack") unless stack.size() == 1
                fail("Expected one element on the subrepos") unless stack[0].subrepos.size() == 1
                @root = stack[0].subrepos[0]

                self
            end

            def to_naft()
                lines = []
                level = 0
                prev_level = 0
                state = nil
                recurse(on_open: ->(repo, base_dir){
                        lines << "#{'  '*level}[Repo](rel:#{repo.rel})(sha:#{repo.sha})"
                        lines << "#{'  '*level}{" if repo.has_subrepos?()
                        
                        level += 1
                    },
                    on_close: ->(repo, base_dir){
                        level -= 1

                        lines << "#{'  '*level}}" if repo.has_subrepos?()
                        
                    },
                )
                lines << nil

                lines*"\n"
            end
        end
    end
end