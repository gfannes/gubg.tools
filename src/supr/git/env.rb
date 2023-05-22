require('supr/cmd')
require('supr/log')

module Supr
    module Git

        class Env
            def initialize(dir)
                @dir = (Module === dir ? dir.dir() : dir)
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
            
            def update_submodule(reldir)
                run_(%w[submodule update --init], reldir)
            end

            def fetch()
                run_('fetch')
            end

            def dirty_files()
                res = []

                re_m = / M (.+)/
                re_d = / D (.+)/
                Supr::Cmd.run([%w[git -C], @dir, %w[status -s]], chomp: true) do |line|
                    if md = re_m.match(line)
                        fp = md[1]
                        fp = File.join(@dir, fp)
                        res << fp unless File.directory?(fp)
                    elsif md = re_d.match(line)
                        fp = md[1]
                        res << fp
                    end
                end

                res
            end

            def checkout(arg)
                run_('checkout', arg)
            end

            def reset_hard(sha)
                run_('reset', '--hard')
            end

            def system(*args)
                args = args.flatten().compact().map{|e|e.to_s()}
                scope("Running 'git #{args*' '}' in '#{@dir}'", level: 3) do |out|
                    Kernel.system('git', '-C', @dir, *args)
                end
            end

            private
            def run_(*args)
                args = args.flatten().compact().map{|e|e.to_s()}

                scope("Running 'git #{args*' '}' in '#{@dir}'", level: 3) do |out|
                    Supr::Cmd.run('git', '-C', @dir, *args)
                end
            end
        end

    end
end
