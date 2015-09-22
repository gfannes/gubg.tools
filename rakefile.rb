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
def link_unless_exists(old, new)
    ln_s(old, new) unless (File.exist?(new) or File.symlink?(new))
end

task :declare do
    publish('src/bash', '*', dst: 'bin')
    publish('src', 'vim/**/*.vim')
    Rake::Task['declare:git_tools'].invoke
end

task :define => :declare do
    link_unless_exists(gubg('vim'), File.join(ENV['HOME'], '.vim'))
    link_unless_exists(gubg('vim', 'config.linux.vim'), File.join(ENV['HOME'], '.vimrc'))
    link_unless_exists(gubg('bin', 'dotinputrc'), File.join(ENV['HOME'], '.inputrc'))
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
