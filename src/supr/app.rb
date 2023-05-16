require('supr/options')
require('supr/log')
require('supr/git')

module Supr
    class App
        def initialize()
            @options = Options.new()
        end

        def call()
            set_log_level(@options.verbose_level)

            toplevel_dir = Supr::Git.toplevel_dir(@options.root_dir)

            @state = Supr::Git::State.new(toplevel_dir: toplevel_dir)
                if @options.state_fp
                    scope("Collecting state from '#{toplevel_dir}'", level: 1) do |out|
                        out.fail("State file '#{@options.state_fp}' does not exist") unless File.exists?(@options.state_fp)
                        content = File.read(@options.state_fp)
                        @state.from_naft(content)
                        @state.apply(force: @options.force)
                    end
                else
                    scope("Collecting state from '#{toplevel_dir}'", level: 1) do |out|
                        @state.from_dir()
                    end
                end

            if @options.help
                puts(@options.help)
            elsif !@options.rest.empty?()
                @verb = @options.rest.shift()
                @rest = @options.rest

                scope("Running verb '#{@verb}'", level: 1) do |out|
                    method = "run_#{@verb}_".to_sym()
                    out.fail("Unknown verb '#{@verb}'") unless self.respond_to?(method, true)

                    self.send(method)
                end
            end
        end

        private
        def run_collect_()
            name = @rest[0]

            @state.name = name

            str = @state.to_naft()

            fp = @options.output_fp || (name && "#{name}.supr") || 'output.supr'
            scope("Writing state to '#{fp}'", level: 1) do
                File.write(fp, str)
            end
        end

        def run_branch_()
            branch = @options.branch || @rest[0]
            error("No branch was specified") unless branch

            @state.branch(branch, delete: @options.delete, force: @options.force)
        end

        def run_push_()
            @state.push()
        end

        def run_run_()
            @state.run(@rest)
        end
    end
end
