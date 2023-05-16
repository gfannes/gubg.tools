require('optparse')

module Supr
    class Options
        attr_reader(:version)
        attr_reader(:help, :verbose_level, :state_fp, :output_fp, :root_dir, :force, :branch, :delete, :rest)

        def initialize()
            @version = 'v1.0.0'

            help_str = nil
            OptionParser.new() do |opts|
            	opts.banner = "Usage (version #{@version}): supr [verb] [options]* [rest]"
                opts.separator("Verbs")
                {
                    collect: "Collect git repo state in output file",
                    load: "Load a git repo state from input file",
                    clean: "Drop all local changes",
                    branch: "Create local branches for current state, 'reset --hard'-style",
                    switch: "Swich to specified branch",
                    push: "Push local branches to server, 'push --force'-style",
                    run: "Run command",
                    diff: "Show a diff for all dirty files",
                    commit: "Commit all dirty files",
                    sync: "Sync local git repo with given branch",
                    deliver: "Deliver local branches to specified branch",
                }.each do |verb, descr|
                    opts.separator("    #{verb}\t#{descr}")
                end

                opts.separator('Options')
    			opts.on('-h', '--help', 'Print this help') { @help = true }
                opts.on('-V', '--verbose LEVEL', 'Verbosity level') { |level| @verbose_level = level.to_i() }
                opts.on('-s', '--state FILE', 'File containing the required git state') { |file| @state_fp = file }
                opts.on('-o', '--output FILE', 'Output file') { |file| @output_fp = file }
                opts.on('-C', '--root DIR', 'Root dir') { |dir| @root_dir = dir}
    			opts.on('-f', '--force', 'Force') { @force = true }
                opts.on('-b', '--branch NAME', 'Use branch NAME') { |name| @branch = name}
    			opts.on('-d', '--delete', 'Delete branch') { @delete = true }

                opts.separator('Developed by Geert Fannes')

                help_str = opts.to_s()
            end.parse!()

            @verbose_level ||= 1
            @root_dir ||= Dir.pwd()
            @help = help_str if @help

            # We consume ARGV to ensure future `gets()` won't receive its data
            @rest = []
            while arg = ARGV.shift()
                @rest << arg
            end
        end
    end
end

