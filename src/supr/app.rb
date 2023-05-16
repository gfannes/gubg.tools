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

            if @options.help
                puts(@options.help)
            elsif !@options.rest.empty?()
                @verb = @options.rest.shift().to_sym()
                @rest = @options.rest

                toplevel_dir = Supr::Git.toplevel_dir(@options.root_dir)
                @state = Supr::Git::State.new(toplevel_dir: toplevel_dir)

                if @options.state_fp
                    scope("Collecting state from file '#{@options.state_fp}'", level: 1) do |out|
                        out.fail("State file '#{@options.state_fp}' does not exist") unless File.exists?(@options.state_fp)
                        content = File.read(@options.state_fp)
                        @state.from_naft(content)
                        @state.apply(force: @options.force)
                    end
                else
                    scope("Collecting state from dir '#{toplevel_dir}'", level: 1) do |out|
                        # We only allow working with a dirty state for specific verbs
                        # Others require an explicit force
                        force = %i[diff commit].include?(@verb) ? true : @options.force
                        @state.from_dir(force: force)
                    end
                end

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

        def run_diff_()
            @state.diff(@options.rest[0])
        end

        def run_commit_()
            error("No commit message was specified") if @options.rest.empty?()
            msg = @options.rest*"\n"
            @state.commit(msg, force: @options.force)
        end
    end
end
