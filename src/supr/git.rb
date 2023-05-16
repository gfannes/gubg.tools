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
                scope("Running command ", *cmd, level: 1) do |out|
                    Dir.chdir(@toplevel_dir) do
                        Supr::Cmd.run(cmd, chomp: true) do |line|
                            out.(line)
                        end
                    end
                end
            end

            def push()
                scope("Pushing repo", level: 1) do |out|
                    recurse(on_open: ->(repo, base_dir){
                            dir = repo.dir(base_dir)
                            git = ::Git.open(dir)
                            branch_name = git.lib.branch_current()
                            out.("Branch: #{branch_name}", level: 2)

                            fail("I cannot force-push to branch '#{branch_name}'") if @protected_branches.include?(branch_name)

                            begin
                                git.lib.send(:command, 'push', '--set-upstream', 'origin', branch_name)
                            rescue ::Git::FailedError
                                error("Could not push '#{dir}' to branch '#{branch_name}'")
                            end
                        }
                    )
                end
            end

            def branch(branch_name)
                scope("Creating branch '#{branch_name}'", level: 1) do |out|
                    out.fail("I cannot create branches with name '#{branch_name}'") if @protected_branches.include?(branch_name)

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
            end

            def apply(force: nil)
                scope("Applying git state", level: 1) do |out|
                    git = ::Git.open(@toplevel_dir)
                    out.("Running 'git fetch'"){git.fetch()}

                    recurse(on_open: ->(repo, base_dir){
                            dir = repo.dir(base_dir)
                            out.("Applying '#{dir}'", level: 2)

                            if File.exists?(File.join(dir, '.git'))
                                out.(".git already present", level: 2)
                            else
                                out.("Updating submodule '#{repo.rel}'", level: 2) do
                                    Supr::Cmd.run(%w[git -C]+[base_dir]+%w[submodule update --init]+[repo.rel])
                                end
                            end

                            git = ::Git.open(dir)
                            if !Supr::Git.is_clean?(dir)
                                git.reset_hard(repo.sha) if force
                                out.fail("Rep '#{dir}' is not clean") unless Supr::Git.is_clean?(dir)
                            end
                        }
                    )
                end
            end

            def from_dir()
                scope("Collecting repo state from '#{@toplevel_dir}'", level: 2) do |out|
                    @root = Repo.new(rel: '', sha: ::Git.open(@toplevel_dir).log.first.sha)

                    repo_stack = [@root]
                    recurse = ->(base_dir){
                        out.("Processing '#{base_dir}'", level: 2)
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
            end

            def from_naft(str)
                scope("Loading repo state from naft string", level: 2) do |out|
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

                    out.fail("Expected one element on the stack") unless stack.size() == 1
                    out.fail("Expected one element on the subrepos") unless stack[0].subrepos.size() == 1
                    @root = stack[0].subrepos[0]

                    self
                end
            end

            def to_naft()
                scope("Writing repo state to naft string", level: 2) do |out|
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
end