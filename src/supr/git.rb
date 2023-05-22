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
                m.each do |sm|
                    g = Git::Env.new(sm)
                    sm.sha = g.sha()
                    sm.my_branch = g.branch()
                    puts sm
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

        def self.apply(m, force: nil)
            scope("Applying git state", level: 1) do |out|
                m.each do |sm|
                    out.("Applying '#{sm.sha}' for '#{sm}'", level: 3) do
                        git_fp = sm.filepath('.git')
                        out.(".git: #{git_fp}")
                        if File.exists?(git_fp)
                            out.(".git is present", level: 3)
                        else
                            out.("Updating submodule '#{sm}'", level: 2) do
                                g = Git::Env.new(sm.parent_absdir())
                                g.update_submodule(sm.path)
                            end
                        end

                        g = Git::Env.new(sm)

                        my_sha = g.sha()
                        if my_sha == sm.sha
                            out.("Repo is already in state '#{my_sha}'", level: 3)
                        else
                            g.fetch()
                        
                            is_clean = out.("Checking if submodule '#{sm}' is clean", level: 2) do
                                fps = g.dirty_files()
                                fps.each do |fp|
                                    out.("'#{fp}' is dirty", level: 1)
                                end
                                fps.empty?()
                            end

                            out.fail("Repo '#{sm}' is not clean") if !is_clean && !force

                            if @@protected_branches.include?(g.branch())
                                out.("checkout '#{sm.sha}'", level: 3) do
                                    g.checkout(sm.sha)
                                end
                            else
                                out.("reset --hard '#{sm.sha}'", level: 3) do
                                    g.reset_hard(sm.sha)
                                end
                            end
                        end
                    end
                end
            end
        end

        def self.diff(m, difftool: nil)
            scope("Diffing dirty files", level: 1) do |out|
                m.each do |sm|
                    g = Git::Env.new(sm)

                    dirty_files = g.dirty_files()
                    if !dirty_files.empty?()
                        out.("Showing diff for '#{sm}'", level: 0)
                        dirty_files.each do |fp|
                            out.warning(" * '#{fp}'")
                        end
                        out.("❓ Show details? (Y/n)", level: 0)
                        answer = gets().chomp()
                        if !%w[n no].include?(answer)
                            g.system(difftool || %w[diff --no-ext-diff], dirty_files)
                        end
                    end
                end
            end
        end

        def self.clean(m, force: nil)
            scope("Cleaning repo", level: 1) do |out|
                m.each do |sm|
                    g = Git::Env.new(sm)

                    dirty_files = g.dirty_files()
                    if !dirty_files.empty?()
                        out.warning("Cleaning #{dirty_files.size()} files from '#{sm}'") do
                            if force
                                dirty_files.each do |fp|
                                    out.("Restoring original state for '#{fp}' in '#{sm}'") do
                                        g.checkout(fp)
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

        def self.commit(m, msg, force: nil)
            scope("Committing dirty files", level: 1) do |out|
                m.each do |sm|
                    g = Git::Env.new(sm)

                    dirty_files = g.dirty_files()
                    if !dirty_files.empty?()
                        out.warning("Committing #{dirty_files.size()} files in '#{sm}'") do
                            my_branch = g.branch()

                            if @@protected_branches.include?(my_branch) && !force
                                out.fail("Direct commit to '#{my_branch}' is not allowed in '#{sm}'")
                            else
                                dirty_files.each do |fp|
                                    out.(" * '#{fp}'", level: 0)
                                    g.add(fp)
                                end
                                g.commit(msg)
                            end
                        end
                    end
                end
            end
        end

        def self.status(m)
            scope("Showing dirty files", level: 1) do |out|
                m.each do |sm|
                    g = Git::Env.new(sm)

                    dirty_files = g.dirty_files()
                    if !dirty_files.empty?()
                        out.("Found #{dirty_files.size()} dirty files for '#{sm}'", level: 0)
                        dirty_files.each do |fp|
                            out.warning(" * '#{fp}'")
                        end
                    end
                end
            end
        end

        def self.run(root_dir, *cmd, &block)
            scope("Running command ", *cmd, level: 1) do |out|
                Dir.chdir(root_dir) do
                    Supr::Cmd.run(cmd, chomp: true) do |line|
                        out.(line)
                        block.(line) if block
                    end
                end
            end
        end

        def self.pull(m, continue: nil, where: nil, force: nil, noop: nil)
            scope("Pulling repos", level: 1) do |out|
                m.each do |sm|
                    out.("Pulling '#{sm}'", level: 3) do
                        g = Git::Env.new(sm)

                        my_branch = g.branch()
                        out.("my_branch: #{my_branch}", level: 3)

                        if where && where != my_branch
                            out.warning("Skipping '#{sm}', its branch '#{my_branch}' does not match with '#{where}'")
                        else
                            if !my_branch
                                out.warning("No branch present for '#{sm}'")
                            else
                                do_stash_pop = false
                                dirty_files = g.dirty_files()
                                if !dirty_files.empty?()
                                    dirty_files.each do |fp|
                                        out.warning(" * #{fp}")
                                    end
                                    out.fail("Found #{dirty_files.size()} dirty files") unless force

                                    out.("Pushing local stash") do
                                        g.stash_push()
                                        do_stash_pop = true
                                    end
                                end
                                out.("Pulling branch '#{my_branch}' for '#{sm}'", noop: noop) do
                                    g.pull(allow_fail: continue)
                                end
                                if do_stash_pop
                                    out.("Popping local stash") do
                                        g.stash_pop()
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        def self.push(m, continue: nil, where: nil, noop: nil)
            scope("Pushing repos", level: 1) do |out|
                m.each do |sm|
                    out.("Pushing '#{sm}'", level: 3) do
                        g = Git::Env.new(sm)
                    
                        my_branch = g.branch()
                        out.("my_branch: #{my_branch}", level: 3)

                        if where && where != my_branch
                            out.warning("Skipping '#{sm}', its branch '#{my_branch}' does not match with '#{where}'")
                        else
                            if !my_branch
                                out.warning("No branch present for '#{sm}'")
                            elsif @@protected_branches.include?(my_branch)
                                out.("Pushing special branch '#{my_branch}' for '#{sm}' without --set-upstream", noop: noop) do
                                    g.push(allow_fail: continue)
                                end
                            else
                                out.("Pushing normal branch '#{my_branch}' for '#{sm}' with --set-upstream", noop: noop) do
                                    g.push(branch: my_branch, allow_fail: continue)
                                end
                            end
                        end
                    end
                end
            end
        end

        def self.create(m, branch_name, delete: nil, where: nil, force: nil, noop: nil)
            scope("#{delete ? 'Deleting' : 'Creating'} local branch '#{branch_name}' from '#{@root_dir}'", level: 1) do |out|
                out.fail("No branch name was specified") unless branch_name
                out.fail("I cannot #{delete ? 'delete' : 'create'} branches with name '#{branch_name}'") if @@protected_branches.include?(branch_name)

                m.each do |sm|
                    out.("Processing '#{sm}'", level: 2) do
                        g = Git::Env.new(sm)

                        my_branch = g.branch()

                        if delete
                            if g.branches().include?(branch_name)
                                if my_branch == branch_name
                                    out.fail("Cannot remove branch '#{branch_name}' that is currently checked-out in '#{sm}'") unless force
                                    out.("Checking-out detached head at '#{sm.sha}'", noop: noop) do
                                        g.checkout(sm.sha)
                                    end
                                end
                                out.("Deleting branch '#{branch_name}'", level: 2, noop: noop) do
                                    g.delete_branch(branch_name)
                                end
                            end
                        else
                            out.fail("Cannot create/update branch '#{branch_name}' for dirty repo '#{sm}'") unless g.dirty_files().empty?()
                            if where && my_branch != where
                                out.warning("Skipping '#{sm}', its branch '#{my_branch}' does not match with '#{where}'")
                            else
                                if g.branches().include?(branch_name)
                                    out.("Resetting branch '#{branch_name}' to '#{sm.sha}'", level: 2, noop: noop) do
                                        g.switch(branch_name)
                                        g.reset_hard(sm.sha)
                                    end
                                else
                                    if force
                                        out.("Creating new branch '#{branch_name}' at '#{sm.sha}'", level: 2, noop: noop) do
                                            g.create_branch(branch_name)
                                            g.switch(branch_name)
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
        end

        def self.switch(m, branch_name, continue: nil)
            scope("Switching to branch '#{branch_name}'", level: 1) do |out|
                m.each do |sm|
                    g = Git::Env.new(sm, allow_fail: continue)

                    g.fetch()

                    out.("Switch to branch '#{branch_name}' in '#{sm}'", level: 2) do
                        branches = g.branches()
                        if !branches.include?(branch_name)
                            out.warning("No branch '#{branch_name}' found in '#{sm}'")
                        end
                        g.switch(branch_name)
                    end
                end
            end
        end

        def self.sync(m, branch_name, where: nil, continue: nil)
            scope("Syncing with branch '#{branch_name}'", level: 0) do |out|
                m.each do |sm|
                    out.("Syncing '#{sm}'", level: 1) do
                        g = Git::Env.new(sm)
                    
                        my_branch = g.branch()
                        out.("Local branch '#{my_branch}'")

                        g.fetch()

                        if !my_branch
                            out.warning("No branch found for '#{sm}'")
                        elsif where && my_branch != where
                            out.warning("Skipping '#{sm}', its branch '#{my_branch}' does not match with '#{where}'")
                        elsif my_branch == branch_name
                            out.("Rebasing branch '#{branch_name}' for '#{sm}'") do
                                g.pull(allow_fail: continue)
                            end
                        else
                            out.("Syncing local branch '#{my_branch}' for '#{sm}' with '#{branch_name}'", level: 2) do
                                g.switch(branch_name)
                                g.pull(allow_fail: continue)
                                g.switch(my_branch)
                                g.rebase(branch_name, allow_fail: continue)
                            end
                        end
                    end
                end
            end
        end

        def self.deliver(m, branch_name)
            scope("Delivering local branches onto '#{branch_name}'", level: 0) do |out|
                m.each do |sm|
                    g = Git::Env.new(sm)

                    my_branch = g.branch()

                    if my_branch && my_branch != branch_name
                        out.("Delivering '#{my_branch}' onto '#{branch_name}' for '#{sm}'", level: 2) do
                            if g.can_fast_forward?(branch_name, my_branch)
                                g.switch(branch_name)
                                g.reset_hard(my_branch)
                            end
                        end
                    end
                end
            end
        end
    end
end