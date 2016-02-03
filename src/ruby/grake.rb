#!/usr/bin/env ruby

require('fileutils')
require('open3')

re = /^(.+):(\d+):(\d+): error: (.+)$/

cmd = "rake #{ARGV*' '}"
Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
    fn = nil
    while line = stderr.gets
        if md = re.match(line)
            fn, row, col, msg = md[1], md[2], md[3], md[4]
            puts("#{fn} on line #{row}: #{msg}")
            %w[build_publish gubg].each do |var|
                pub = ENV[var]
                if fn.start_with?(pub)
                    fn[pub] = ''
                    raise fn
                end
            end
            if fn[0] != '/'
                puts("Opening \"#{fn}\"")
                if !system("ggg #{fn} #{row}")
                    raise("User requested to stop")
                end
                sleep(0.1)
            else
                puts("Skipping this error, it is not ours")
            end
        end
    end
end

# output_fn = 'grake.output.txt'
# FileUtils.rm(output_fn)
# system("rake #{ARGV*' '} &> #{output_fn}")
# File.open(output_fn, 'r') do |fi|
#     fn = nil
#     output.lines.each do |line|
#         if md = re.match(line)
#             if md[1] != fn
#                 fn = md[1]
#                 row = md[2]
#                 col = md[3]
#                 puts("Opening \"#{fn}\"")
#                 `gg #{fn} #{row}`
#                 sleep(0.1)
#             end
#         end
#     end
# end
