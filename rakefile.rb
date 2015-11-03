require(File.join(ENV['gubg'], 'shared'))
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
        git_clone('https://github.com/rking', 'ag.vim')
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
    Dir.chdir(shared_dir('extern')) do
        git_clone('https://git.tasktools.org/scm/tm', 'task') do
            Dir.mkdir('build')
            Dir.chdir('build') do
                sh 'cmake ..'
                sh 'make -j 4'
                %w[calc lex task].each{|exe|cp "src/#{exe}", shared_dir('bin')}
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
            {qs: 'git status', qd: 'git diff', qc: 'git commit -a', qp: 'git pull --rebase', qq: 'git push', ql: 'git log -n 5'}.each do |fn, cmd|
                File.open(fn.to_s, "w", 0755){|fo|puts("creating #{fn}");fo.puts(bash);fo.puts(cmd+' $1 $2 $3 $4 $5')} unless File.exist?(fn.to_s)
            end
        end
    end
end
