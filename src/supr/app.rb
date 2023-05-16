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

            toplevel_dir = Supr::Git.toplevel_dir(@options.root_dir)

            @state = Supr::Git::State.new(toplevel_dir: toplevel_dir)
            if @options.state_fp
                fail("State file '#{@options.state_fp}' does not exist") unless File.exists?(@options.state_fp)
                content = File.read(@options.state_fp)
                @state.from_naft(content)
            else
                @state.from_dir()
            end

            method = "run_#{verb}_".to_sym()
            fail("Unknown verb '#{verb}'") unless self.respond_to?(method, true)

            self.send(method)
        end

        private
        def run_help_()
            puts(@options.help)
        end

        def run_apply_()
            @state.apply(force: @options.force)
        end

        def run_collect_()
            fp = @options.output_fp || 'supr.naft'
            File.write(fp, @state.to_naft())
        end

        def run_branch_()
            branch = @options.branch || @options.rest[0]
            fail("No branch was specified") unless branch

            @state.branch(branch)
        end

        def run_push_()
            @state.push()
        end

        def run_run_()
            output = @state.run(@options.rest)
            puts(output)
        end
    end
end
