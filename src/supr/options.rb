require('optparse')

module Supr
    class Options
        attr_reader(:verb, :help, :verbose_level, :state_fp, :output_fp, :root_dir, :force, :branch, :rest)

        def initialize()
            @verb = ARGV.shift() if ARGV[0] && ARGV[0][0] != '-'

            OptionParser.new() do |opts|
            	opts.banner = 'Usage: supr [verb] [options]* [rest]'
                opts.separator("Verbs")
                {
                    help: "Print this help",
                    collect: "Collect git repo state in output file",
                    branch: "Create local branches for current state, 'reset --hard'-style",
                    push: "Push local branches to server, 'push --force'-style",
                    run: "Run command",
                }.each do |verb, descr|
                    opts.separator("    #{verb}\t#{descr}")
                end

                opts.separator('Options')
    			opts.on('-h', '--help', 'Print this help') { @verb = :help }
                opts.on('-V', '--verbose LEVEL', 'Verbosity level') { |level| @verbose_level = level.to_i() }
                opts.on('-s', '--state FILE', 'File containing the required git state') { |file| @state_fp = file }
                opts.on('-o', '--output FILE', 'Output file') { |file| @output_fp = file }
                opts.on('-C', '--root DIR', 'Root dir') { |dir| @root_dir = dir}
    			opts.on('-f', '--force', 'Force') { @force = true }
                opts.on('-b', '--branch NAME', 'Use branch NAME') { |name| @branch = name}

                opts.separator('Developed by Geert Fannes')

                @help = opts.to_s()
            end.parse!()

            @root_dir ||= Dir.pwd()

            @rest = ARGV
        end
    end
end

