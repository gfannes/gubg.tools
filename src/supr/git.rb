require('supr/cmd')
require('supr/log')

require('git')
require('pathname')

module Supr
    module Git
        def self.toplevel_dir(dir)
            dir = Supr::Cmd.run(%w[git rev-parse --show-superproject-working-tree])
            dir = Supr::Cmd.run(%w[git rev-parse --show-toplevel]) if dir.empty?()
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
        end

        class State
            attr_accessor(:root)

            def initialize()
                @root = nil
            end

            def push(toplevel_dir)
                dirs = [toplevel_dir]
                recurse = ->(repo){
                    dir = File.join(dirs[-1], repo.rel)
                    git = ::Git.open(dir)
                    branch = git.lib.branch_current()
                    os(2, "Branch: #{branch}")

                    fail("I cannot force-push to branch '#{branch}'") if %w[master stable main develop].include?(branch)

                    begin
                        git.lib.send(:command, 'push', '--set-upstream', 'origin', branch)
                    rescue ::Git::FailedError
                        error("Could not push '#{dir}' to branch '#{branch}'")
                    end

                    dirs.push(dir)
                    repo.subrepos.each do |subrepo|
                        recurse.(subrepo)
                    end
                    dirs.pop()
                }
                recurse.(@root)
            end

            def branch(toplevel_dir, name)
                dirs = [toplevel_dir]
                recurse = ->(repo){
                    dir = File.join(dirs[-1], repo.rel)
                    git = ::Git.open(dir)
                    if git.is_branch?(name)
                        git.checkout(name)
                        git.reset_hard(repo.sha)
                    else
                        git.lib.branch_new(name)
                    end
                    git.checkout(name)

                    dirs.push(dir)
                    repo.subrepos.each do |subrepo|
                        recurse.(subrepo)
                    end
                    dirs.pop()
                }
                recurse.(@root)
            end

            def apply(toplevel_dir, force: nil)
                git = ::Git.open(toplevel_dir)
                git.fetch()

                dirs = [toplevel_dir]
                gits = [git]
                recurse = ->(repo){
                    dir = File.join(dirs[-1], repo.rel)
                    os(2, "Applying '#{dir}'")

                    if File.exists?(File.join(dir, '.git'))
                        os(2, ".git already present")
                    else
                        os(2, "Updating submod")
                        Supr::Cmd.run(%w[git -C]+[dirs[-1]]+%w[submodule update --init]+[repo.rel])
                    end

                    git = ::Git.open(dir)
                    if !Supr::Git.is_clean?(dir)
                        git.reset_hard(repo.sha) if force
                        fail("Rep '#{dir}' is not clean") unless Supr::Git.is_clean?(dir)
                    end

                    dirs.push(dir)
                    gits.push(git)
                    repo.subrepos.each do |subrepo|
                        recurse.(subrepo)
                    end
                    gits.pop()
                    dirs.pop()
                }
                recurse.(@root)
            end

            def from_dir(toplevel_dir)
                @root = Repo.new(rel: '', sha: ::Git.open(toplevel_dir).log.first.sha)

                stack = [@root]
                recurse = ->(dir){
                    Supr::Git.submodules(dir).each do |rel|
                        submod_dir = File.join(dir, rel)

                        repo = Repo.new(
                            rel: rel,
                            sha: ::Git.open(submod_dir).log.first.sha,
                        )
                        stack[-1].subrepos << repo
            
                        stack.push(repo)
                        recurse.(submod_dir)
                        stack.pop()
                    end
                }
                recurse.(toplevel_dir)

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
                recurse = ->(repo){
                    lines << "#{'  '*level}[Repo](rel:#{repo.rel})(sha:#{repo.sha})"
                    if !repo.subrepos.empty?()
                        lines << "#{'  '*level}{"
                        level += 1
                        repo.subrepos.each do |subrepo|
                            recurse.(subrepo)
                        end
                        level -= 1
                        lines << "#{'  '*level}}"
                    end
                }
                recurse.(@root)
                lines << nil

                lines*"\n"
            end
        end
    end
end