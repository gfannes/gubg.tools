require('supr/options')
require('supr/log')
require('supr/git')

module Supr
    class App
        def initialize()
            @options = Options.new()
        end

        def call()
            set_os(@options.verbose_level)

            verb = @options.verb
            if !verb
                error("No verb was specified")
                verb = :help
            end

            method = "run_#{verb}_".to_sym()
            fail("Unknown verb '#{verb}'") unless self.respond_to?(method, true)

            self.send(method)
        end

        private
        def run_help_()
            puts(@options.help)
        end

        def run_setup_()
            fail("Input was not set") unless @options.input_fp
            fail("Input file '#{@options.input_fp}' does not exist") unless File.exists?(@options.input_fp)
            content = File.read(@options.input_fp)
            state = Supr::Git::State.new().from_naft(content)

            puts(state.to_naft())

            toplevel_dir = Supr::Git.toplevel_dir(@options.root_dir)
            state.apply(toplevel_dir, force: @options.force)
        end

        def run_collect_()
            toplevel_dir = Supr::Git.toplevel_dir(@options.root_dir)

            state = Supr::Git::State.new().from_dir(toplevel_dir)

            fp = @options.output_fp || 'supr.naft'
            File.write(fp, state.to_naft())
        end

        def run_branch_()
            branch = @options.branch || @options.rest[0]
            fail("No branch was specified") unless branch

            toplevel_dir = Supr::Git.toplevel_dir(@options.root_dir)

            state = Supr::Git::State.new().from_dir(toplevel_dir)
            state.branch(toplevel_dir, branch)
        end

        def run_push_()
            toplevel_dir = Supr::Git.toplevel_dir(@options.root_dir)

            state = Supr::Git::State.new().from_dir(toplevel_dir)
            state.push(toplevel_dir)
        end
    end
end
