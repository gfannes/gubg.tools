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
                verb = @options.rest.shift().to_sym()
                @rest = @options.rest

                toplevel_dir = Supr::Git.toplevel_dir(@options.root_dir)
                @state = Supr::Git::State.new(toplevel_dir: toplevel_dir)

                if %i[collect clean diff commit branch push run sync].include?(verb)
                    scope("Collecting state from dir '#{toplevel_dir}'", level: 1) do |out|
                        # We only allow working with a dirty state for specific verbs
                        # Others require an explicit force
                        force = %i[diff commit clean branch].include?(verb) ? true : @options.force
                        @state.from_dir(force: force)
                    end
                end

                scope("Running verb '#{verb}'", level: 1) do |out|
                    method = "run_#{verb}_".to_sym()
                    out.fail("Unknown verb '#{verb}'") unless self.respond_to?(method, true)

                    self.send(method)
                end
            end
        end

        private
        def run_collect_()
            name = @rest[0]

            @state.name = name

            fp = @options.output_fp || (name && "#{name}.supr") || 'output.supr'
            scope("Writing state to '#{fp}'", level: 1) do
                str = @state.to_naft()
                File.write(fp, str)
            end
        end

        def run_clean_()
            @state.clean(force: @options.force)
        end

        def run_load_()
            name = @rest[0]
            state_fp = @options.state_fp || (name && "#{name}.supr")

            scope("Collecting state from file '#{state_fp}'", level: 1) do |out|
                out.fail("State file '#{state_fp}' does not exist") unless File.exists?(state_fp)
                @state.from_naft(File.read(state_fp))
                @state.apply(force: @options.force)
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

        def run_sync_()
            branch = @options.branch || @rest[0]
            error("No branch was specified") unless branch

            @state.sync(branch)
        end
    end
end
