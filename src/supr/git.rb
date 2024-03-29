require('supr/cmd')
require('supr/log')
require('supr/git/env')

require('pathname')
require('time')

module Supr
    module Git

        @@protected_branches = %w[master stable feature main develop release]

        def self.collect_sha_and_branch(m)
            scope("Collect SHA checksums and branch info for '#{m.root_absdir()}'", level: 1) do |out|
                sha__sm = {}
                m.each do |sm|
                    git = Git::Env.new(sm)
                    sm.sha = git.sha()
                    sm.my_branch = git.branch()

                    out.fail("Submodule '#{sm}' has the same hash as '#{sha__sm[sm.sha]}', is it checked-out correctly?") if sha__sm.has_key?(sm.sha)
                    sha__sm[sm.sha] = sm
                end
            end
        end

        def self.to_naft(m)
            scope("Writing repo state to naft string", level: 2) do |out|
                lines = []
                level = 0

                attr = ->(key, val) { lines[-1] << "(#{key}:#{val})" unless NilClass === val }

                recurse = ->(sm) do
                    lines << "#{'  '*level}[Module]"
                    attr.('name', sm.name)
                    attr.('path', sm.path)
                    attr.('url', sm.url)
                    attr.('sync_branch', sm.sync_branch)
                    attr.('sha', sm.sha)
                    attr.('my_branch', sm.my_branch)

                    lines << "#{'  '*level}{" if sm.has_submodules?()
                    sm.submodules().each do |sm|
                        level += 1
                        recurse.(sm)
                        level -= 1
                    end
                    lines << "#{'  '*level}}" if sm.has_submodules?()
                end

                recurse.(m)

                lines << nil
                lines*"\n"
            end
        end

        def self.from_naft(content)
            scope("Loading repo state from naft string", level: 2) do |out|
                root = nil

                # @todo: Use real naft parsing

                re_open = /{/
                re_close = /}/
                re_module = /\[Module\](.+)/
                re_attr = /\(([^:]+):([^)]+)\)/

                module_stack = []
                m = nil
                content.each_line() do |line|
                    line = line.chomp()

                    if md = re_module.match(line)
                        m = Module.new(nil)
                        attrs = md[1]
                        attrs.scan(re_attr).each do |md|
                            key, val = md[0], md[1]
                            m.send("#{key}=".to_sym(), val)
                        end

                        root = m unless root

                        if !module_stack.empty?()
                            parent = module_stack[-1]
                            m.parent_absdir = parent.filepath()
                            parent.submodules << m
                        end
                    elsif re_open.match(line)
                        module_stack.push(m)
                    elsif re_close.match(line)
                        module_stack.pop()
                    end
                end

                out.fail("Expected empty module_stack") unless module_stack.empty?()
                out.fail("Expected root to be set") unless root

                root
            end
        end

        def self.apply(m, force: nil, &block)
            scope("Applying git state", level: 1) do |out|
                m.each do |sm|
                    out.("Applying '#{sm.sha}' for '#{sm}'", level: 3) do
                        block.("Applying '#{sm.sha}' for '#{sm}'") if block
                        git_fp = sm.filepath('.git')
                        out.fail("Invalid path to .git") unless git_fp

                        if File.exist?(git_fp)
                            out.(".git is present", level: 3)
                        else
                            out.("Updating submodule '#{sm}'", level: 2) do
                                git = Git::Env.new(sm.parent_absdir())
                                git.update_submodule(sm.path)
                            end
                        end

                        git = Git::Env.new(sm)

                        my_sha = git.sha()
                        if my_sha == sm.sha
                            out.("Repo is already in state '#{my_sha}'", level: 3)
                        else
                            git.fetch()
                        
                            is_clean = out.("Checking if submodule '#{sm}' is clean", level: 2) do
                                fps = git.dirty_files()
                                fps.each do |fp|
                                    out.("'#{fp}' is dirty", level: 1)
                                end
                                fps.empty?()
                            end

                            out.fail("Repo '#{sm}' is not clean") if !is_clean && !force

                            if @@protected_branches.include?(git.branch())
                                out.("checkout '#{sm.sha}'", level: 3) do
                                    git.checkout(sm.sha)
                                end
                            else
                                out.("reset --hard '#{sm.sha}'", level: 3) do
                                    git.reset_hard(sm.sha)
                                end
                            end
                        end
                    end
                end
            end
        end

        def self.diff(m, difftool: nil, where: nil)
            scope("Diffing dirty files", level: 1) do |out|
                m.each do |sm|
                    git = Git::Env.new(sm)

                    my_branch = git.branch()

                    if where && my_branch != where
                        out.info("Skipping '#{sm}', its branch '#{my_branch}' does not match with '#{where}'")
                    else
                        dirty_files = git.dirty_files()
                        if !dirty_files.empty?()
                            out.("Showing diff for '#{sm}'", level: 0)
                            dirty_files.each do |fp|
                                out.warning(" * '#{fp}'")
                            end
                            out.("❓ Show details? (Y/n)", level: 0)
                            answer = gets().chomp()
                            if !%w[n no].include?(answer)
                                git.system(difftool || %w[diff --no-ext-diff], dirty_files)
                            end
                        end
                    end
                end
            end
        end

        def self.clean(m, force: nil)
            scope("Cleaning repo", level: 1) do |out|
                m.each do |sm|
                    git = Git::Env.new(sm)

                    dirty_files = git.dirty_files()
                    if !dirty_files.empty?()
                        out.warning("Cleaning #{dirty_files.size()} files from '#{sm}'") do
                            if force
                                dirty_files.each do |fp|
                                    out.("Restoring original state for '#{fp}' in '#{sm}'") do
                                        git.checkout(fp)
                                    end
                                end
                            else
                                out.fail("Cleaning requires the force option")
                            end
                        end
                    end
                end
            end
        end

        def self.commit(m, msg, where: nil, force: nil)
            scope("Committing dirty files", level: 1) do |out|
                m.each do |sm|
                    git = Git::Env.new(sm)

                    my_branch = git.branch()

                    if where && my_branch != where
                        out.info("Skipping '#{sm}', its branch '#{my_branch}' does not match with '#{where}'")
                    else
                        dirty_files = git.dirty_files()
                        if !dirty_files.empty?()
                            out.warning("Committing #{dirty_files.size()} files in '#{sm}'") do
                                my_branch = git.branch()

                                if @@protected_branches.include?(my_branch) && !force
                                    out.fail("Direct commit to '#{my_branch}' is not allowed in '#{sm}'")
                                else
                                    dirty_files.each do |fp|
                                        out.(" * '#{fp}'", level: 0)
                                        git.add(fp)
                                    end
                                    git.commit(msg)
                                end
                            end
                        end
                    end
                end
            end
        end

        def self.status(m, where: nil)
            scope("Showing dirty files", level: 1) do |out|
                m.each do |sm|
                    git = Git::Env.new(sm)

                    my_branch = git.branch()
                    if where && my_branch != where
                    else
                        dirty_files = git.dirty_files()
                        if !dirty_files.empty?()
                            out.("Found #{dirty_files.size()} dirty files for '#{sm}'", level: 0)
                            dirty_files.each do |fp|
                                out.warning(" * '#{fp}'")
                            end
                        end
                    end
                end
            end
        end

        def self.run(root_dir, *cmd, &block)
            env, cli, args = {}, nil, []
            cmd.flatten().each do |e|
                if NilClass === cli
                    parts = e.split('=')
                    if parts.size() == 2
                        env[parts[0]] = parts[1]
                    else
                        cli = e
                    end
                else
                    args << e
                end
            end
            scope("Running command '#{cli}' with args '#{args*' '}' for env '#{env}'", level: 1) do |out|
                Dir.chdir(root_dir) do
                    Supr::Cmd.run(cli, *args, env: env, chomp: true) do |line|
                        out.(line)
                        block.(line) if block
                    end
                end
            end
        end

        def self.pull(m, continue: nil, where: nil, force: nil, noop: nil, j: nil)
            scope("Pulling repos", level: 1) do |out|
                m.each_mt(j: j) do |sm|
                    out.("Pulling '#{sm}'", level: 3) do
                        git = Git::Env.new(sm)

                        my_branch = git.branch()
                        out.("my_branch: #{my_branch}", level: 3)

                        if where && where != my_branch
                            out.info("Skipping '#{sm}', its branch '#{my_branch}' does not match with '#{where}'")
                        else
                            if !my_branch
                                out.warning("No branch present for '#{sm}'")
                            else
                                do_stash_pop = false
                                dirty_files = git.dirty_files()
                                if !dirty_files.empty?()
                                    dirty_files.each do |fp|
                                        out.warning(" * #{fp}")
                                    end
                                    out.fail("Found #{dirty_files.size()} dirty files") unless force

                                    out.("Pushing local stash") do
                                        git.stash_push()
                                        do_stash_pop = true
                                    end
                                end
                                out.("Pulling branch '#{my_branch}' for '#{sm}'", noop: noop) do
                                    git.pull(allow_fail: continue)
                                end
                                if do_stash_pop
                                    out.("Popping local stash") do
                                        git.stash_pop()
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        def self.push(m, continue: nil, where: nil, force: nil, noop: nil, j: nil)
            scope("Pushing repos", level: 1) do |out|
                m.each_mt(j: j) do |sm|
                    out.("Pushing '#{sm}'", level: 3) do
                        git = Git::Env.new(sm)
                    
                        my_branch = git.branch()
                        out.("my_branch: #{my_branch}", level: 3)

                        if where && where != my_branch
                            out.info("Skipping '#{sm}', its branch '#{my_branch}' does not match with '#{where}'")
                        else
                            if !my_branch
                                out.warning("No branch present for '#{sm}'")
                            elsif @@protected_branches.include?(my_branch)
                                out.("Pushing special branch '#{my_branch}' for '#{sm}'", noop: noop) do
                                    git.push(allow_fail: continue)
                                end
                            else
                                out.("Pushing normal branch '#{my_branch}' for '#{sm}'", noop: noop) do
                                    unless force
                                        dst_branch = "origin/#{my_branch}"
                                        out.fail("Cannot ffwd '#{dst_branch}' to '#{my_branch}' for '#{sm}'") unless git.can_fast_forward?(dst_branch, my_branch)
                                    end
                                    git.push(branch: my_branch, force: force, allow_fail: continue)
                                end
                            end
                        end
                    end
                end
            end
        end

        def self.stash(m, args, where: nil)
            scope("Stashing with '#{args}' in '#{@root_dir}'", level: 1) do |out|
                m.each do |sm|
                    out.("Processing '#{sm}'", level: 2) do
                        git = Git::Env.new(sm)

                        my_branch = git.branch()

                        if where && my_branch != where
                            out.info("Skipping '#{sm}', its branch '#{my_branch}' does not match with '#{where}'")
                        else
                            case args[0]
                            when 'apply'
                                if !git.stash_list().empty?()
                                    git.stash(*args)
                                end
                            else
                                git.stash(*args)
                            end
                        end
                    end
                end
            end
        end

        def self.create(m, branch_name, where: nil, force: nil, noop: nil)
            scope("Creating local branches '#{branch_name}' from '#{@root_dir}'", level: 1) do |out|
                out.fail("No branch name was specified") unless branch_name
                out.fail("I cannot create branches with name '#{branch_name}'") if @@protected_branches.include?(branch_name)

                m.each do |sm|
                    out.("Processing '#{sm}'", level: 2) do
                        git = Git::Env.new(sm)

                        my_branch = git.branch()

                        out.fail("Cannot create/update branch '#{branch_name}' for dirty repo '#{sm}'") unless git.dirty_files().empty?()
                        if where && my_branch != where
                            out.info("Skipping '#{sm}', its branch '#{my_branch}' does not match with '#{where}'")
                        else
                            if git.branches().include?(branch_name)
                                out.("Resetting branch '#{branch_name}' to '#{sm.sha}'", level: 2, noop: noop) do
                                    git.switch(branch_name)
                                    git.reset_hard(sm.sha)
                                end
                            else
                                if force
                                    out.("Creating new branch '#{branch_name}' at '#{sm.sha}'", level: 2, noop: noop) do
                                        git.create_branch(branch_name)
                                        git.switch(branch_name)
                                    end
                                else
                                    out.warning("Branch '#{branch_name}' does not exist yet for '#{sm}', I will only create with with force")
                                end
                            end
                        end
                    end
                end
            end
        end

        def self.delete(m, branch_name, force: nil, noop: nil)
            scope("Deleting local branches '#{branch_name}' from '#{@root_dir}'", level: 1) do |out|
                out.fail("No branch name was specified") unless branch_name
                out.fail("I cannot delete branches with name '#{branch_name}'") if @@protected_branches.include?(branch_name)

                m.each do |sm|
                    out.("Processing '#{sm}'", level: 2) do
                        git = Git::Env.new(sm)

                        my_branch = git.branch()

                        if git.branches().include?(branch_name)
                            if my_branch == branch_name
                                out.fail("Cannot remove branch '#{branch_name}' that is currently checked-out in '#{sm}'") unless force
                                out.("Checking-out detached head at '#{sm.sha}'", noop: noop) do
                                    git.checkout(sm.sha)
                                end
                            end
                            out.("Deleting branch '#{branch_name}'", level: 1, noop: noop) do
                                git.delete_branch(branch_name)
                            end
                        end
                    end
                end
            end
        end

        def self.switch(m, branch_name, where: nil, continue: nil, j: nil)
            scope("Switching to branch '#{branch_name}'", level: 1) do |out|
                m.each_mt(j: j) do |sm|
                    out.("Switching to branch '#{branch_name}' in '#{sm}'", level: 1) do
                        git = Git::Env.new(sm, allow_fail: continue)

                        my_branch = git.branch()

                        if where && my_branch != where
                            out.info("Skipping '#{sm}', its branch '#{my_branch}' does not match with '#{where}'")
                        else
                            git.fetch()
                            branches = git.branches()
                            if !branches.include?(branch_name)
                                out.warning("No branch '#{branch_name}' found in '#{sm}'")
                            end
                            git.switch(branch_name)
                        end
                    end
                end
            end
        end

        def self.sync(m, branch_name, where: nil, continue: nil, j: nil)
            scope("Syncing with branch '#{branch_name}'", level: 0) do |out|
                m.each_mt(j: j) do |sm|
                    out.("Syncing '#{sm}'", level: 1) do
                        git = Git::Env.new(sm)
                    
                        my_branch = git.branch()
                        out.("Local branch '#{my_branch}'")

                        git.fetch()

                        if !my_branch
                            out.warning("No branch found for '#{sm}'")
                        elsif where && my_branch != where
                            out.info("Skipping '#{sm}', its branch '#{my_branch}' does not match with '#{where}'")
                        elsif my_branch == branch_name
                            out.("Rebasing branch '#{branch_name}' for '#{sm}'") do
                                git.pull(allow_fail: continue)
                            end
                        else
                            out.("Syncing local branch '#{my_branch}' for '#{sm}' with '#{branch_name}'", level: 2) do
                                git.switch(branch_name)
                                git.pull(allow_fail: continue)
                                git.switch(my_branch)
                                git.rebase(branch_name, allow_fail: continue)
                            end
                        end
                    end
                end
            end
        end

        def self.deliver(m, branch_name, where: nil)
            scope("Delivering local branches onto '#{branch_name}'", level: 0) do |out|
                m.each do |sm|
                    git = Git::Env.new(sm)

                    my_branch = git.branch()

                    if !my_branch
                        out.warning("No branch found for '#{sm}'")
                    elsif my_branch == branch_name
                        out.info("Delivering to the same branch '#{my_branch}' is useless")
                    elsif where && my_branch != where
                        out.info("Skipping '#{sm}', its branch '#{my_branch}' does not match with '#{where}'")
                    else
                        out.("Delivering '#{my_branch}' onto '#{branch_name}' for '#{sm}'", level: 2) do
                            if !git.can_fast_forward?(branch_name, my_branch)
                                out.fail("Cannot deliver '#{my_branch}' onto '#{branch_name}' via FFWD")
                            else
                                git.switch(branch_name)
                                git.reset_hard(my_branch)
                            end
                        end
                    end
                end
            end
        end
    end
end