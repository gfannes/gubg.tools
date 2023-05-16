$global_log_level = nil

def set_log_level(level)
    $global_log_level = level
    $global_log_level.freeze()
end

$global_scope_level = 0

module Supr
    class Logger
        def initialize(level)
            @level = level

            @start_time = Time.now()
        end

        def output(prefix, *args, level: nil)
            if $global_log_level >= (level || @level)
                now = Time.now()
                puts(prefix*$global_scope_level+' '+args.map{|e|e.to_s}*''+" (#{now-@start_time}s)")
            end
        end

        def call(*args, level: nil, &block)
            res = nil
            if block
                $global_scope_level += 1
                output('  ', '🠚 ', *args, level: level)
                res = block.()
                output('  ', '🠘 ', *args, level: level)
                $global_scope_level -= 1
            else
                output('  ', *args, level: level)
            end
            res
        end

        def fail(*args)
            output('☠ ', *args, level: 0)
            raise('Fatal error')
        end

        def warning(*args, &block)
            res = nil
            if block
                $global_scope_level += 1
                output('⛈ ', '🠚 ', *args, level: 0)
                res = block.()
                output('⛈ ', '🠘 ', *args, level: 0)
                $global_scope_level -= 1
            else
                output('⛈ ', *args, level: 0)
            end
            res
        end

        def self.open(*args, level:, &block)
            $global_scope_level += 1 if $global_log_level >= level
            logger = Logger.new(level)
            logger.output('🠚 ', *args)
            res = block.(logger)
            logger.output('🠘 ', *args)
            $global_scope_level -= 1 if $global_log_level >= level
            res
        end
    end
end

def scope(*args, level:, &block)
    Supr::Logger.open(*args, level: level, &block)
end

def error(*args)
    scope(*args, level: 0) do |out|
        out.fail('Error: ', *args)
    end
end


