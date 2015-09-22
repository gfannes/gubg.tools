task :default => :help
task :help do
end

def gubg(*parts)
    raise('ERROR: You have to specify the gubg destination dir via the environment vairable "gubg"') unless ENV.has_key?('gubg')
    File.join(ENV['gubg'], *parts.compact)
end
def publish(src, pattern, na = {dst: nil})
    dst = gubg(na[:dst])
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
    publish('src', 'vim/**/*.vim')
    Rake::Task['declare:git_tools'].invoke
end

task :define do
    dot_vim = File.join(ENV['HOME'], '.vim')
    ln_s(gubg('vim'), dot_vim) unless (File.exist?(dot_vim) or File.symlink?(dot_vim))
    dot_vimrc = File.join(ENV['HOME'], '.vimrc')
    ln_s(gubg('vim', 'config.linux.vim'), dot_vimrc) unless (File.exist?(dot_vimrc) or File.symlink?(dot_vimrc))
end

namespace :declare do
    #git_tools
    task :git_tools do
        bash = "\#!"+`which bash`
        Dir.chdir(gubg('bin')) do
            [
                {name: 'qs', command: 'git status'},
                {name: 'qd', command: 'git diff'},
                {name: 'qc', command: 'git commit -a'},
                {name: 'qp', command: 'git pull --rebase'},
            ].each do |h|
                if not File.exist?(h[:name])
                    puts("Creating #{h[:name]}")
                    File.open(h[:name], "w"){|fo|fo.puts(bash);fo.puts(h[:command])}
                    File.chmod(0755, h[:name])
                end
            end
        end
    end
end
