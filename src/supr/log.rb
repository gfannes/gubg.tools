def error(*args)
    puts('Error: '+args.map{|e|e.to_s()}*'')
end

$my_os_level = nil

def set_os(level)
    $my_os_level = level || 0
end

def os(level, *args)
    puts("Level#{level}: "+args.map{|e|e.to_s()}*'') if $my_os_level >= level
end
