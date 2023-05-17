$global_log_level = nil

def set_log_level(level)
    $global_log_level = level
    $global_log_level.freeze()
end

$global_add_time = false
def set_add_time(b)
    $global_add_time = b
end

$global_scope_level = 0

module Supr
    class Logger
        def initialize(level)
            @level = level

            @start_time = Time.now()
        end

        def do_log(level)
            $global_log_level >= (level || @level)
        end

        def output(prefix, *args)
            now = Time.now()
            time_diff = ($global_add_time ? " (#{now-@start_time}s)" : '')
            puts(prefix*$global_scope_level+' '+args.map{|e|e.to_s()}*''+time_diff)
        end

        def call(*args, level: nil, noop: nil, &block)
            noop_sym = (noop ? '⛔' : '')
            res = nil
            if block
                if do_log(level)
                    output('  ', '🠚 ', noop_sym, *args)
                    $global_scope_level += 1
                end
                res = block.() unless noop
                if do_log(level)
                    $global_scope_level -= 1
                    output('  ', '🠘 ', noop_sym, *args)
                end
            else
                output('  ', *args) if do_log(level)
            end
            res
        end

        def fail(*args)
            sym = '💀'
            output(sym, *args)
            raise('Fatal error')
        end

        def warning(*args, &block)
            sym = '⚠️ '

            res = nil
            if block
                $global_scope_level += 1
                output(sym, '🠚 ', *args)
                res = block.()
                output(sym, '🠘 ', *args)
                $global_scope_level -= 1
            else
                output(sym, *args)
            end
            res
        end

        def info(*args, &block)
            sym = 'ℹ️ '

            res = nil
            if block
                $global_scope_level += 1
                output(sym, '🠚 ', *args)
                res = block.()
                output(sym, '🠘 ', *args)
                $global_scope_level -= 1
            else
                output(sym, *args)
            end
            res
        end

        def self.open(*args, level:, &block)
            logger = Logger.new(level)
            if logger.do_log(level)
                $global_scope_level += 1
                logger.output('🠚 ', *args)
            end
            res = block.(logger)
            if logger.do_log(level)
                logger.output('🠘 ', *args)
                $global_scope_level -= 1
            end
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


