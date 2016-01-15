#!/usr/bin/env ruby

output = `ag #{ARGV*' '}`
re = /^(.+):(\d+):/
fn = nil
output.lines.each do |line|
    if md = re.match(line)
        if md[1] != fn
            fn = md[1]
            puts("Opening \"#{fn}\"")
            `gg #{fn}`
            sleep(0.1)
        end
    else
        puts("Could not understand \"#{line}\"")
    end
end
