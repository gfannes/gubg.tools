require('fileutils')

module GUBG
    def shared(*parts)
        raise('ERROR: You have to specify the shared destination dir via the environment vairable "gubg"') unless ENV.has_key?('gubg')
        File.join(ENV['gubg'], *parts.compact)
    end
    def shared_file(*parts)
        fn = shared(*parts)
        raise("File \"#{fn}\" does not exist") unless File.exist?(fn)
        fn
    end
    def shared_dir(*parts)
        dir = shared(*parts)
        FileUtils.mkdir_p(dir) unless File.exist?(dir)
        dir
    end
    def publish(src, pattern, na = {dst: nil, mode: nil})
        dst = shared(na[:dst])
        Dir.chdir(src) do
            FileList.new(pattern).each do |fn|
                dst_fn = File.join(dst, fn)
                dst_dir = File.dirname(dst_fn)
                FileUtils.mkdir_p(dst_dir) unless File.exist?(dst_dir)
                FileUtils.install(fn, dst_dir, mode: na[:mode]) unless (File.exist?(dst_fn) and FileUtils.identical?(fn, dst_fn))
            end
        end
    end
    def link_unless_exists(old, new)
        ln_s(old, new) unless (File.exist?(new) or File.symlink?(new))
    end
    def git_clone(uri, name)
        if not File.exist?(name)
            Rake.sh("git clone #{uri}/#{name}")
            Dir.chdir(name) {yield} if block_given?
        end
    end
end

include GUBG
task :default => :help
task :help do
    puts("The following tasks can be specified:")
    puts("* declare: installs bash, vim and git scripts to GUBG.shared")
    puts("* define: creates symbolic link to the installed vim scripts and .inputrc")
end

task :declare do
    publish('src/bash', '*', dst: 'bin', mode: 0755)
    publish('src', 'vim/**/*.vim')
    Rake::Task['declare:git_tools'].invoke
    Dir.chdir(shared_dir('vim', 'bundle')) do
        git_clone('https://github.com/Valloric', 'YouCompleteMe') do
            sh 'git submodule update --recursive --init'
            sh './install.sh'
        end
        git_clone('https://github.com/tpope', 'vim-commentary')
        git_clone('https://github.com/tpope', 'vim-fugitive')
        git_clone('https://github.com/pangloss', 'vim-javascript')
        git_clone('https://github.com/vim-scripts', 'SearchComplete')
        git_clone('git://git.wincent.com', 'command-t') do
            Dir.chdir('ruby/command-t') do
                sh 'ruby extconf.rb'
                sh 'make'
            end
        end
    end
end

task :define => :declare do
    link_unless_exists(shared_dir('vim'), File.join(ENV['HOME'], '.vim'))
    link_unless_exists(shared_file('vim', 'config.linux.vim'), File.join(ENV['HOME'], '.vimrc'))
    link_unless_exists(shared_file('bin', 'dotinputrc'), File.join(ENV['HOME'], '.inputrc'))
end

namespace :declare do
    task :git_tools do
        bash = "\#!"+`which bash`
        Dir.chdir(shared_dir('bin')) do
            {qs: 'git status', qd: 'git diff', qc: 'git commit -a', qp: 'git pull --rebase'}.each do |fn, cmd|
                File.open(fn.to_s, "w", 0755){|fo|puts("creating #{fn}");fo.puts(bash);fo.puts(cmd)} unless File.exist?(fn.to_s)
            end
        end
    end
end
