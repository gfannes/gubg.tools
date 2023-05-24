require('optparse')

module Supr
    class Options
        attr_reader(:version)
        attr_reader(:print_help, :help_msg, :j, :verbose_level, :time, :state_fp, :output_fp, :root_dir, :force, :continue, :where, :ip, :port, :noop, :rest)

        def initialize()
            @version = 'v1.0.3'.freeze()

            # We set @continue to `false` to allow Supr::Cmd.run() to discriminate between commands that
            # can be continued, and others
            @continue = false

            OptionParser.new() do |opts|
            	opts.banner = "Usage (version #{@version}): supr [verb] [options]* [rest]"
                verbs = [
                    {
                        verb: :collect,
                        value: :name,
                        descr: "Collect git modules state in output file",
                    },
                    {
                        verb: :load,
                        flags: %i[force],
                        value: :name,
                        descr: "Load a git modules state from input file",
                    },
                    {
                        verb: :clean,
                        flags: %i[where force],
                        descr: "Drop all local changes",
                    },
                    {
                        verb: :create,
                        flags: %i[where force noop],
                        value: :branch,
                        descr: "Create local branches for current state",
                    },
                    {
                        verb: :delete,
                        flags: %i[force noop],
                        value: :branch,
                        descr: "Delete local branches",
                    },
                    {
                        verb: :switch,
                        flags: %i[where continue jobs],
                        value: :branch,
                        descr: "Swich to specified branch",
                    },
                    {
                        verb: :pull,
                        flags: %i[where continue force noop jobs],
                        descr: "Pull checked-out branches from server, where",
                    },
                    {
                        verb: :push,
                        flags: %i[where continue force noop jobs],
                        descr: "Push local branches to server",
                    },
                    {
                        verb: :status,
                        flags: %i[where],
                        descr: "Show dirty state",
                    },
                    {
                        verb: :diff,
                        flags: %i[where],
                        value: :difftool,
                        descr: "Show a diff for all dirty files. Difftool can also come from $supr_difftool",
                    },
                    {
                        verb: :commit,
                        flags: %i[where force],
                        value: 'msg*',
                        descr: "Commit all dirty files",
                    },
                    {
                        verb: :sync,
                        flags: %i[where continue jobs],
                        value: :branch,
                        descr: "Sync local git modules with specified branch, if local branch is present",
                    },
                    {
                        verb: :deliver,
                        flags: %i[where],
                        value: :branch,
                        descr: "Deliver local branches to specified branch",
                    },
                    {
                        verb: :run,
                        descr: "\tRun command",
                    },
                    {
                        verb: :remote,
                        value: :ip,
                        descr: "Remote run command, special command 'stop' will stop the server",
                    },
                    {
                        verb: :serve,
                        flags: %i[force],
                        value: :port,
                        descr: "Start a TCP server on specified port",
                    },
                ]

                opts.separator("\tVerb\tWhere\tForce\tNoOp\tContue\tJobs\tValue")
                verbs.each do |h|
                    verb, flags, value, descr = *h.values_at(*%i[verb flags value descr])
                    yn = ->(flag){(flags && flags.include?(flag)) ? '  v' : '  .'}
                    opts.separator("\t#{verb}\t#{yn.(:where)}\t#{yn.(:force)}\t#{yn.(:noop)}\t#{yn.(:continue)}\t#{yn.(:jobs)}\t#{value}\t\t#{descr}")
                end

                opts.separator('Common options')
                opts.on('-w', '--where BRANCH', 'Only run commands for modules at BRANCH, default is $supr_where') { |branch| @where = branch}
    			opts.on('-f', '--force', 'Force') { @force = true }
    			opts.on('-c', '--continue', 'Continue') { @continue = true }
    			opts.on('-n', '--noop', 'No operation mode') { @noop = true }
    			opts.on('-j', '--jobs COUNT', 'Thread count') { |count| @j = count.to_i()}

                opts.separator('Other options')
    			opts.on('-h', '--help', 'Print this help') { @print_help = true }
                opts.on('-V', '--verbose LEVEL', 'Verbosity level') { |level| @verbose_level = level.to_i() }
                opts.on('-s', '--state FILE', 'File containing the required git state') { |file| @state_fp = file }
                opts.on('-o', '--output FILE', 'Output file') { |file| @output_fp = file }
                opts.on('-C', '--root DIR', 'Root dir') { |dir| @root_dir = dir}
    			opts.on('-t', '--time', 'Add timing info') { @time = true }
    			opts.on('-i', '--IP ADDRESS', 'IP address') { |ip| @ip = ip}
    			opts.on('-p', '--port PORT', 'TCP port') { |port| @port = port.to_i()}

                opts.separator('Developed by Geert Fannes')

                @help_msg = opts.to_s()
            end.parse!()

            @verbose_level ||= 1
            @root_dir ||= Dir.pwd()
            @where ||= ENV['supr_where']

            # We consume ARGV to ensure future `gets()` won't receive its data
            @rest = []
            while arg = ARGV.shift()
                @rest << arg
            end
        end
    end
end

