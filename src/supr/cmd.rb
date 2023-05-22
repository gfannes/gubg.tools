require('supr/log')

require('open3')

module Supr
    module Cmd

        def self.run(*args, env: nil, chomp: nil, allow_fail: nil, &block)
            args = [args].flatten().map{|e|e.to_s()}

            scope("Running command '#{args*' '}' with env '#{env}'", level: 4) do |out|
                orig_env = {}
                env.each do |k, v|
                    orig_env[k] = v
                end if env

                output = nil
                status = nil

                if block
                    Open3.popen2e(*args) do |input, output, thread|
                        input.close()
                        output.each_line do |line|
                            line = line.chomp() if chomp
                            block.(line)
                        end
                        status = thread.value
                    end
                else
                    output, status = Open3.capture2(*args)
                    output = output.chomp() if chomp
                end

                if !status.success?
                    if allow_fail
                        out.warning("Could not run '#{args*' '}'")
                    else
                        out.info("Please use the `--continue` option to continue after this failure") if FalseClass === allow_fail
                        out.fail("Could not run '#{args*' '}'")
                    end
                end

                orig_env.each do |k, v|
                    ENV[k] = v
                end if env

                output
            end
        end

    end
end