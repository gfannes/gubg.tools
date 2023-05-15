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

            mode = @options.mode
            if !mode
                error("No mode was specified")
                mode = :help
            end

            self.send("run_#{mode}_".to_sym())
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
            os(3, "toplevel_dir: #{toplevel_dir}")

            state = Supr::Git::State.new().from_dir(toplevel_dir)

            fp = @options.output_fp || 'supr.naft'
            File.write(fp, state.to_naft())
        end
    end
end
