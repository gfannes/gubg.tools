require('supr/log')

require('open3')

module Supr
    module Cmd
        def self.run(*args)
            args = [args].flatten()
            output, status = Open3.capture2(*args)
            if !status.success?
                fail("Could not run '#{args*' '}'")
            end
            output.chomp()
        end
    end
end