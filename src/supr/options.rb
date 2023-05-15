require('optparse')

module Supr
    class Options
        attr_reader(:verb, :help, :verbose_level, :input_fp, :output_fp, :root_dir, :force, :branch, :rest)

        def initialize()
            @verb = ARGV.shift() if ARGV[0] && ARGV[0][0] != '-'

            OptionParser.new() do |opts|
            	opts.banner = 'Usage: supr [verb] [options]*'
    			opts.on('-h', '--help', 'Print this help') { @verb = :help }
                opts.on('-V', '--verbose LEVEL', 'Verbosity level') { |level| @verbose_level = level.to_i() }
                opts.on('-i', '--input FILE', 'Input file') { |file| @input_fp = file }
                opts.on('-o', '--output FILE', 'Output file') { |file| @output_fp = file }
                opts.on('-C', '--root DIR', 'Root dir') { |dir| @root_dir = dir}
    			opts.on('-f', '--force', 'Force') { @force = true }
                opts.on('-b', '--branch NAME', 'Use branch NAME') { |name| @branch = name}

                @help = opts.to_s()
            end.parse!()

            @root_dir ||= Dir.pwd()

            @rest = ARGV
        end
    end
end

