require('supr/log')

require('open3')

module Supr
    module Cmd

        def self.run(*args, chomp: nil, &block)
            output = nil
            status = nil

            args = [args].flatten()
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
                fail("Could not run '#{args*' '}'")
            end

            output
        end

    end
end