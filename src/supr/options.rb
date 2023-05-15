require('optparse')

module Supr
    class Options
        attr_reader(:mode, :help, :verbose_level, :input_fp, :output_fp, :root_dir, :force)

        def initialize()
            OptionParser.new() do |opts|
            	opts.banner = 'Usage: supr [options]'
    			opts.on('-h', '--help', 'Print this help') { @mode = :help }
                opts.on('-m', '--mode MODE', 'Operation mode') { |mode| @mode = mode.to_sym() }
                opts.on('-V', '--verbose LEVEL', 'Verbosity level') { |level| @verbose_level = level.to_i() }
                opts.on('-i', '--input FILE', 'Input file') { |file| @input_fp = file }
                opts.on('-o', '--output FILE', 'Output file') { |file| @output_fp = file }
                opts.on('-C', '--root DIR', 'Root dir') { |dir| @root_dir = dir}
    			opts.on('-f', '--force', 'Force') { @force = true }

                @help = opts.to_s()
            end.parse!()

            @root_dir ||= Dir.pwd()
        end
    end
end

