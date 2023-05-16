require('supr/cmd')
require('supr/log')

require('git')
require('pathname')
require('time')

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

        # Returns the dirty files, relative from `dir`, as returned by `git status -s`
        def self.dirty_files(dir)
            res = []

            re_m = / M (.+)/
            re_d = / D (.+)/
            Supr::Cmd.run([%w[git -C], dir, %w[status -s]], chomp: true) do |line|
                if md = re_m.match(line)
                    fp = md[1]
                    res << fp unless File.directory?(File.join(dir, fp))
                elsif md = re_d.match(line)
                    fp = md[1]
                    res << fp
                end
            end

            res
        end

        def self.branches(dir)
            res = []

            Supr::Cmd.run([%w[git -C], dir, 'branch'], chomp: true) do |line|
                res << line[2, line.size()]
            end

            res
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
            attr_accessor(:name, :root)

            def initialize(name: nil, toplevel_dir: nil)
                @toplevel_dir = toplevel_dir
                @name = name

                @root = nil
                @protected_branches = %w[master stable feature main develop].freeze()
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

            def commit(msg, force: nil)
                scope("Committing dirty files", level: 1) do |out|
                    recurse(
                        on_open: ->(repo, base_dir){
                            dir = repo.dir(base_dir)

                            dirty_files = Supr::Git.dirty_files(dir)
                            if !dirty_files.empty?()
                                out.warning("Committing #{dirty_files.size()} files in '#{rel_(dir)}'") do
                                    git = ::Git.open(dir)
                                    branch = git.current_branch()
                                    if @protected_branches.include?(branch) && !force
                                        out.fail("Direct commit to '#{branch}' is not allowed in '#{rel_(dir)}'")
                                    else
                                        dirty_files.each do |fp|
                                            out.(" * '#{fp}'", level: 0)
                                            git.add(fp)
                                        end
                                        git.commit(msg)
                                    end
                                end
                            end
                        }
                    )
                end
            end

            def diff(difftool = nil)
                scope("Diffing dirty files", level: 1) do |out|
                    recurse(
                        on_open: ->(repo, base_dir){
                            dir = repo.dir(base_dir)

                            dirty_files = Supr::Git.dirty_files(dir)
                            if !dirty_files.empty?()
                                out.("Showing diff for '#{dir}'", level: 0)
                                dirty_files.each do |fp|
                                    out.warning(" * '#{fp}'")
                                end
                                out.("Show details? (Y/n)", level: 0)
                                answer = gets().chomp()
                                if !%w[n no].include?(answer)
                                    args = [%w[git -C], dir, difftool || %w[diff --no-ext-diff], dirty_files].flatten()
                                    puts(args)
                                    system(*args)
                                end
                            end
                        }
                    )
                end
            end

            def clean(force: nil)
                scope("Cleaning repo", level: 1) do |out|
                    recurse(
                        on_open: ->(repo, base_dir){
                            dir = repo.dir(base_dir)

                            dirty_files = Supr::Git.dirty_files(dir)
                            if !dirty_files.empty?()
                                out.warning("Cleaning #{dirty_files.size} files from '#{rel_(dir)}'") do
                                    if force
                                        dirty_files.each do |fp|
                                            out.("Restoring original state for '#{fp}' in '#{rel_(dir)}'") do
                                                Supr::Cmd.run(*[%w[git -C], dir, 'checkout', fp])
                                            end
                                        end
                                    else
                                        out.fail("Cleaning requires the force option")
                                    end
                                end
                            end
                        }
                    )
                end
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

                            out.fail("I cannot force-push to branch '#{branch_name}'") if @protected_branches.include?(branch_name)

                            ok = if branch_name
                                begin
                                    git.lib.send(:command, 'push', '--set-upstream', 'origin', branch_name)
                                    true
                                rescue ::Git::FailedError
                                    false
                                end
                            end

                            out.warning("Could not push '#{dir}' to branch '#{branch_name}'") unless ok
                        }
                    )
                end
            end

            def branch(branch_name, delete: nil, force: nil)
                scope("#{delete ? 'Deleting' : 'Creating'} local branche '#{branch_name}' from '#{@toplevel_dir}'", level: 1) do |out|
                    out.fail("No branch name was specified") unless branch_name
                    out.fail("I cannot #{delete ? 'delete' : 'create'} branches with name '#{branch_name}'") if @protected_branches.include?(branch_name)

                    recurse(on_open: ->(repo, base_dir){
                            dir = repo.dir(base_dir)
                            out.("Processing '#{dir}'", level: 2) do
                                git = ::Git.open(dir)
                                if delete
                                    if git.is_branch?(branch_name)
                                        if git.current_branch() == branch_name
                                            out.fail("Cannot remove branch '#{branch_name}' that is currently checked-out in '#{dir}'")  unless force
                                            git.checkout(repo.sha)
                                        end
                                        out.("Deleting branch '#{branch_name}'", level: 2) do
                                            git.branch(branch_name).delete()
                                        end
                                    end
                                else
                                    out.fail("Cannot create/update branch '#{branch_name}' for dirty repo '#{rel_(dir)}'") unless Supr::Git.dirty_files(dir).empty?()
                                    if Supr::Git.branches(dir).include?(branch_name)
                                        out.("Resetting branch '#{branch_name}' to '#{repo.sha}'", level: 2) do
                                            git.checkout(branch_name)
                                            git.reset_hard(repo.sha)
                                        end
                                    else
                                        out.("Creating new branch '#{branch_name}' at '#{repo.sha}'", level: 2) do
                                            git.lib.branch_new(branch_name)
                                            git.checkout(branch_name)
                                        end
                                    end
                                end
                            end
                        }
                    )
                end
            end

            def sync(branch_name)
                scope("Syncing with branch '#{branch_name}'") do |out|
                    Supr::Cmd.run([%w[git -C], @toplevel_dir, 'fetch'])
                    recurse(
                        on_open: ->(repo, base_dir){
                            dir = repo.dir(base_dir)
                            out.("Syncing '#{rel_(dir)}'", level: 2) do
                                Supr::Cmd.run([%w[git -C], dir, 'rebase', branch_name])
                            end
                        }
                    )
                end
            end

            def apply(force: nil)
                scope("Applying git state", level: 1) do |out|
                    git = ::Git.open(@toplevel_dir)
                    out.("Running 'git fetch'"){git.fetch()}

                    recurse(
                        on_open: ->(repo, base_dir){
                            dir = repo.dir(base_dir)
                            out.("Applying '#{rel_(dir)}'", level: 3) do
                                if File.exists?(File.join(dir, '.git'))
                                    out.(".git is present", level: 3)
                                else
                                    out.("Updating submodule '#{repo.rel}'", level: 2) do
                                        Supr::Cmd.run(%w[git -C]+[base_dir]+%w[submodule update --init]+[repo.rel])
                                    end
                                end
                                
                                is_clean = out.("Checking if submodule '#{rel_(dir)}' is clean", level: 2) do
                                    fps = Supr::Git.dirty_files(dir)
                                    fps.each do |fp|
                                        out.("'#{fp}' is dirty", level: 1)
                                    end
                                    fps.empty?()
                                end

                                out.fail("Repo '#{dir}' is not clean") if !is_clean && !force

                                git = ::Git.open(dir)
                                if @protected_branches.include?(git.current_branch())
                                    git.checkout(repo.sha)
                                else
                                    git.reset_hard(repo.sha)
                                end
                            end
                        }
                    )
                end
            end

            def from_dir(force: nil)
                scope("Collecting repo state from '#{@toplevel_dir}'", level: 2) do |out|
                    @root = Repo.new(rel: '', sha: ::Git.open(@toplevel_dir).log.first.sha)

                    repo_stack = [@root]
                    recurse = ->(base_dir){
                        out.("Processing '#{base_dir}'", level: 2)
                        Supr::Git.submodules(base_dir).each do |rel|
                            submod_dir = File.join(base_dir, rel)

                            all_clean = true
                            Supr::Git.dirty_files(submod_dir).each do |fp|
                                out.warning("'#{fp}' is dirty in '#{rel_(submod_dir)}'")
                                all_clean = false
                            end
                            out.fail("Found dirty files in '#{rel_(submod_dir)}'") if !all_clean && !force

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
                    re_state = /\[State\]\(name:([^)]*)\)\(toplevel:([^)]*)\)\(date:([^)]*)\)/
                    re_repo = /\[Repo\]\(rel:([^)]*)\)\(sha:([\da-f]*)\)/

                    stack = []
                    root_root = nil
                    last_repo = nil

                    str.each_line do |line|
                        out.("line: #{line.chomp()}", level: 3)

                        if md = re_state.match(line)
                            out.("Found State", level: 3)
                            @name ||= md[1]
                            @toplevel_dir ||= md[2]
                            @date ||= md[3]
                            last_repo = Repo.new()
                            root_root = last_repo
                        elsif md = re_repo.match(line)
                            out.("Found Repo", level: 3)
                            last_repo = Repo.new(rel: md[1], sha: md[2])
                            stack[-1].subrepos << last_repo
                        elsif re_open.match(line)
                            stack << last_repo
                        elsif re_close.match(line)
                            stack.pop
                        end
                    end

                    out.fail("Expected one element on the stack") unless stack.size() == 0
                    out.fail("Expected root_root to be set") unless root_root
                    out.fail("Expected one element on the subrepos") unless root_root.subrepos.size() == 1
                    @root = root_root.subrepos[0]

                    self
                end
            end

            def to_naft()
                scope("Writing repo state to naft string", level: 2) do |out|
                    lines = []

                    lines << "[State](name:#{@name})(toplevel:#{@toplevel_dir})(date:#{Time.now().iso8601()})"
                    lines << "{"

                    level = 1
                    prev_level = level
                    state = nil
                    recurse(
                        on_open: ->(repo, base_dir){
                            git = ::Git.open(repo.dir(base_dir))
                            branch = git.current_branch() ? "(branch:#{git.current_branch()})" : ''

                            lines << "#{'  '*level}[Repo](rel:#{repo.rel})(sha:#{repo.sha})#{branch}"
                            lines << "#{'  '*level}{" if repo.has_subrepos?()
                        
                            level += 1
                        },
                        on_close: ->(repo, base_dir){
                            level -= 1

                            lines << "#{'  '*level}}" if repo.has_subrepos?()
                        
                        },
                    )

                    lines << "}"
                    lines << nil

                    lines*"\n"
                end
            end

            private
            def rel_(dir)
                Pathname.new(dir).relative_path_from(@toplevel_dir)
            end
        end
    end
end