require('optparse')

module Supr
    class Options
        attr_reader(:version)
        attr_reader(:print_help, :help_msg, :j, :verbose_level, :time, :state_fp, :output_fp, :root_dir, :force, :continue, :branch, :where, :ip, :port, :noop, :rest)

        def initialize()
            @version = 'v1.0.2'.freeze()

            # We set @continue to `false` to allow Supr::Cmd.run() to discriminate between commands that
            # can be continued, and others
            @continue = false

            OptionParser.new() do |opts|
            	opts.banner = "Usage (version #{@version}): supr [verb] [options]* [rest]"
                opts.separator("Verbs")
                {
                    collect: "Collect git modules state in output file",
                    load: "Load a git modules state from input file",
                    clean: "Drop all local changes",
                    create: "Create local branches for current state, 'reset --hard'-style, optionally filtered by a current branch that must be checked-out",
                    delete: "Delete local branches",
                    switch: "Swich to specified branch",
                    pull: "Pull checked-out branches from server, where",
                    push: "Push local branches to server, 'push --force'-style, optionally filtered by a current branch that must be checked-out",
                    run: "\tRun command",
                    remote: "Remote run command",
                    status: "Show dirty state",
                    diff: "Show a diff for all dirty files",
                    commit: "Commit all dirty files",
                    sync: "Sync local git modules with specified branch, if local branch is present",
                    deliver: "Deliver local branches to specified branch",
                    serve: "Start a TCP server on specified port",
                }.each do |verb, descr|
                    opts.separator("    #{verb}\t#{descr}")
                end

                opts.separator('Options')
    			opts.on('-h', '--help', 'Print this help') { @print_help = true }
                opts.on('-V', '--verbose LEVEL', 'Verbosity level') { |level| @verbose_level = level.to_i() }
                opts.on('-s', '--state FILE', 'File containing the required git state') { |file| @state_fp = file }
                opts.on('-o', '--output FILE', 'Output file') { |file| @output_fp = file }
                opts.on('-C', '--root DIR', 'Root dir') { |dir| @root_dir = dir}
    			opts.on('-f', '--force', 'Force') { @force = true }
    			opts.on('-c', '--continue', 'Continue') { @continue = true }
                opts.on('-b', '--branch NAME', 'Use branch NAME') { |name| @branch = name}
                opts.on('-w', '--where NAME', 'Use where NAME') { |name| @where = name}
    			opts.on('-t', '--time', 'Add timing info') { @time = true }
    			opts.on('-i', '--IP ADDRESS', 'IP address') { |ip| @ip = ip}
    			opts.on('-p', '--port PORT', 'TCP port') { |port| @port = port.to_i()}
    			opts.on('-n', '--noop', 'No operation mode') { @noop = true }
    			opts.on('-j', '--jobs COUNT', 'Thread count') { |count| @j = count.to_i()}

                opts.separator('Developed by Geert Fannes')

                @help_msg = opts.to_s()
            end.parse!()

            @verbose_level ||= 1
            @root_dir ||= Dir.pwd()

            # We consume ARGV to ensure future `gets()` won't receive its data
            @rest = []
            while arg = ARGV.shift()
                @rest << arg
            end
        end
    end
end

