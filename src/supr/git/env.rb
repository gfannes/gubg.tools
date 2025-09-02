require('supr/cmd')
require('supr/log')

module Supr
    module Git

        class Env
            def initialize(dir, allow_fail: nil)
                @dir = (Module === dir ? dir.filepath() : dir)
                @allow_fail = allow_fail
            end

            def root_dir()
                dir = run_(%w[rev-parse --show-superproject-working-tree]).chomp()
                dir = run_(%w[rev-parse --show-toplevel]).chomp() if dir.empty?()
                dir
            end

            def sha()
                run_('rev-parse', 'HEAD').chomp()
            end

            def branch()
                re = /\* (.+)/
                str = run_('branch').chomp()
                name = re.match(str)[1]
                name = nil if name['HEAD detached at']
                name
            end

            def branches()
                res = []
                run_('branch').each_line do |line|
                    line.chomp!()
                    res << line[2, line.size()]
                end
                res
            end

            def create_branch(name)
                run_('branch', name)
            end

            def delete_branch(name)
                run_('branch', '-D', name)
            end
            
            def update_submodule(reldir)
                run_(%w[submodule update --init], reldir)
            end

            def fetch()
                run_('fetch')
            end

            def dirty_files()
                res = []

                re_m = /M\s+(.+)/
                re_d = /D\s+(.+)/
                Supr::Cmd.run([%w[git -C], @dir, %w[status -s]], chomp: true) do |line|
                    if md = re_m.match(line)
                        fp_rel = md[1]
                        fp_abs = File.join(@dir, fp_rel)
                        res << fp_rel unless File.directory?(fp_abs)
                    elsif md = re_d.match(line)
                        fp_rel = md[1]
                        res << fp_rel
                    end
                end

                res
            end

            def checkout(arg)
                run_('checkout', arg)
            end

            def reset_hard(arg)
                run_('reset', '--hard', arg)
            end

            def system(*args)
                args = args.flatten().compact().map{|e|e.to_s()}
                scope("Running 'git #{args*' '}' in '#{@dir}'", level: 3) do |out|
                    Kernel.system('git', '-C', @dir, *args)
                end
            end

            def add(fp)
                run_('add', fp)
            end

            def commit(msg)
                run_('commit', '-m', msg)
            end

            def switch(branch_name)
                run_('switch', branch_name)
            end

            def stash_push()
                run_('stash', 'push')
            end

            def stash_pop()
                run_('stash', 'pop')
            end

            def rebase(branch_name, allow_fail: nil)
                run_('rebase', branch_name, allow_fail: allow_fail)
            end

            def pull(allow_fail: nil)
                run_('pull', '--rebase', allow_fail: allow_fail)
            end

            def push(branch: nil, force: nil, allow_fail: nil)
                run_('push', branch && ['--set-upstream', 'origin', branch], force && '--force', allow_fail: allow_fail)
            end

            def can_fast_forward?(from, to)
                run_('merge-base', '--is-ancestor', from, to)
            end

            def stash_list()
                run_('stash', 'list')
            end

            def stash(*args)
                run_('stash', *args)
            end

            def remote(type: :fetch)
                run_('remote', '-v')
            end
            
            private
            def run_(*args, allow_fail: nil)
                args = args.flatten().compact().map{|e|e.to_s()}

                scope("Running 'git #{args*' '}' in '#{@dir}'", level: 3) do |out|
                    Supr::Cmd.run('git', '-C', @dir, *args, allow_fail: allow_fail || @allow_fail)
                end
            end
        end

    end
end
