task :default => :help
task :help do
end

def publish(src, pattern, na = {dst: nil})
    raise('ERROR: You have to specify the gubg destination dir via the environment vairable "gubg_dst"') unless ENV.has_key?('gubg_dst')
    gubg_dst = ENV['gubg_dst']
    dst = gubg_dst
    dst = File.join(dst, na[:dst]) if na[:dst]
    Dir.chdir(src) do
        FileList.new(pattern).each do |fn|
            dst_fn = File.join(dst, fn)
            dst_dir = File.dirname(dst_fn)
            mkdir_p(dst_dir) unless File.exist?(dst_dir)
            install(fn, dst_dir) unless (File.exist?(dst_fn) and identical?(fn, dst_fn))
        end
    end
end

task :declare do
    publish('src/bash', '*', dst: 'bin')
    publish('src/vim', '**/*.vim')
end
