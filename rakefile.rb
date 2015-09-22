task :default => :help
task :help do
    puts("The following tasks can be specified:")
    puts("* declare: installs bash, vim and git scripts to $gubg")
    puts("* define: creates symbolic link to the installed vim scripts and .inputrc")
end

def gubg(*parts)
    raise('ERROR: You have to specify the gubg destination dir via the environment vairable "gubg"') unless ENV.has_key?('gubg')
    File.join(ENV['gubg'], *parts.compact)
end
def gubg_file(*parts)
    fn = gubg(*parts)
    raise("File \"#{fn}\" does not exist") unless File.exist?(fn)
    fn
end
def gubg_dir(*parts)
    dir = gubg(*parts)
    mkdir_p(dir) unless File.exist?(dir)
    dir
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
def git_clone(uri, name)
    if not File.exist?(name)
        sh "git clone #{uri}/#{name}"
        Dir.chdir(name) {yield} if block_given?
    end
end

task :declare do
    publish('src/bash', '*', dst: 'bin')
    publish('src', 'vim/**/*.vim')
    Rake::Task['declare:git_tools'].invoke
    Dir.chdir(gubg_dir('vim', 'bundle')) do
        git_clone('https://github.com/Valloric', 'YouCompleteMe') do
            sh 'git submodule update --recursive --init'
            sh './install.sh'
        end
        git_clone('https://github.com/tpope', 'vim-commentary')
        git_clone('https://github.com/tpope', 'vim-fugitive')
        git_clone('https://github.com/pangloss', 'vim-javascript')
        git_clone('git://git.wincent.com', 'command-t') do
            Dir.chdir('ruby/command-t') do
                sh 'ruby extconf.rb'
                sh 'make'
            end
        end
    end
end

task :define => :declare do
    link_unless_exists(gubg_dir('vim'), File.join(ENV['HOME'], '.vim'))
    link_unless_exists(gubg_file('vim', 'config.linux.vim'), File.join(ENV['HOME'], '.vimrc'))
    link_unless_exists(gubg_file('bin', 'dotinputrc'), File.join(ENV['HOME'], '.inputrc'))
end

namespace :declare do
    task :git_tools do
        bash = "\#!"+`which bash`
        Dir.chdir(gubg_dir('bin')) do
            {qs: 'git status', qd: 'git diff', qc: 'git commit -a', qp: 'git pull --rebase'}.each do |fn, cmd|
                File.open(fn.to_s, "w", 0755){|fo|puts("creating #{fn}");fo.puts(bash);fo.puts(cmd)} unless File.exist?(fn.to_s)
            end
        end
    end
end
