require(File.join(ENV['gubg'], 'shared'))
include GUBG

task :default do
    sh "rake -T"
end

task :clean do
    rm_rf '.cache'
end

desc "Prepare this module: install all scripts"
task :prepare do
    extra = %w[vim]
    (%w[bash bat vim vim git]+extra).each do |e|
        Rake::Task["#{e}:prepare"].invoke
    end
end

desc "Run this module: build all apps"
task :run do
    apps = %w[fart vix neovim exvim]
    apps = %w[fart vix exvim]
    apps = %w[vix exvim]
    apps.each do |e|
        Rake::Task["#{e}:run"].invoke
    end
end

namespace :bash do
        task :prepare do
            case os
            when :linux, :osx
                publish('src/bash', dst: 'bin', mode: 0755)
                link_unless_exists(shared_file('bin', 'dotinputrc'), File.join(ENV['HOME'], '.inputrc'))
                publish('src/ruby', dst: 'bin', mode: 0755){|fn|fn.gsub(/\.rb$/,'')}
            end
        end
end
namespace :bat do
        task :prepare do
            case os
            when :windows
                publish('src/bat', dst: 'bin')
            end
        end
end

namespace :gcc do
        task :prepare do
            case os
            when :linux
                which('colorgcc') do |fn|
                    link_unless_exists(fn, shared('bin', 'g++'))
                    link_unless_exists(fn, shared('bin', 'gcc'))
                end
            end
        end
end
namespace :vim do
    task :prepare do
        publish('src', pattern: 'vim/**/*.vim')
        case os
        when :linux
            link_unless_exists(shared_dir('vim'), File.join(ENV['HOME'], '.vim'))
            link_unless_exists(shared_file('vim', 'config.linux.vim'), File.join(ENV['HOME'], '.vimrc'))
            link_unless_exists(shared_file('vim', 'ideavimrc.vim'), File.join(ENV['HOME'], '.ideavimrc'))
            publish('src/vifm', dst: 'install/vifm')
        when :osx
            link_unless_exists(shared_dir('vim'), File.join(ENV['HOME'], '.vim'))
            link_unless_exists(shared_file('vim', 'config.linux.vim'), File.join(ENV['HOME'], '.vimrc'))
            link_unless_exists(shared_file('bin', 'dotinputrc'), File.join(ENV['HOME'], '.inputrc'))
            publish('src/vifm', dst: 'install/vifm')
        when :windows
            publish('src/vim', pattern: '_vimrc', dst: 'vim')
            #Needed for vim backup files
            GUBG::mkdir("C:/temp")
        end
    end
    task :run do
        Dir.chdir(shared_dir('vim', 'bundle')) do
            case os
            when :linux
                #sudo apt-get install cmake python-dev
                git_clone('https://github.com/Valloric', 'YouCompleteMe') do
                    if !File.exist?(build_ok_fn)
                        sh 'git submodule update --recursive --init'
                        sh './install.sh'
                        sh "touch #{build_ok_fn}"
                    end
                end
            when :windows, :osx
            else raise("Unknown os #{os}") end
            git_clone('https://github.com/Frydac', 'vim-tree')
            git_clone('https://github.com/tpope', 'vim-commentary')
            git_clone('https://github.com/rking', 'ag.vim')
            git_clone('https://github.com/tpope', 'vim-fugitive')
            git_clone('https://github.com/pangloss', 'vim-javascript')
            git_clone('https://github.com/vim-scripts', 'SearchComplete')
            git_clone('https://github.com/leafgarland', 'typescript-vim')
            git_clone('https://github.com/ctrlpvim', 'ctrlp.vim')
        end
    end
end
namespace :git do
    task :prepare do
        bash = nil
        args = case os
               when :linux, :osx
                   bash = "\#!"+`which bash`
                   '$1 $2 $3 $4 $5'
               when :windows then '%1 %2 %3 %4 %5'
               else raise("Unknown os #{os}") end
        Dir.chdir(shared_dir('bin')) do
            {
                qs: 'git status',
                #qd: 'git difftool -t meld -Y',
                qd: 'git diff',
                qc: 'git commit -a',
                qp: 'git pull --rebase',
                qq: 'git push',
                ql: 'git log -n 5',
                qm: ['git checkout master', 'git branch -d'],
                qb: 'git checkout -b',
                qx: 'git branch -d',
            }.each do |fn, cmd|
                fn = case os
                     when :linux, :osx then fn.to_s
                     when :windows
                         cmd = "git diff" if fn == :qd
                         "#{fn}.bat"
                     else raise("Unknown os #{os}") end
                File.open(fn, "w", 0755) do |fo|
                    puts("creating #{fn}")
                    case os
                    when :linux, :osx then fo.puts(bash)
                    end
                    fo.puts([cmd].join("\n")+' '+args)
                end unless File.exist?(fn)
            end
        end
    end
end

build_ok_fn = 'gubg.build.ok'
namespace :neovim do
    task :prepare

    case os
    when :linux
        task :build do
            Dir.chdir(shared_dir('extern')) do
                #sudo apt-get install automake libtool-bin
                git_clone('https://github.com/neovim', 'neovim') do
                    if !File.exist?(build_ok_fn)
                        puts("Building neovim")
                        sh 'rm -rf build'
                        sh "make -j 8 CMAKE_EXTRA_FLAGS=\"-DCMAKE_INSTALL_PREFIX:PATH=#{shared_dir('stage', 'neovim')}\""
                        sh 'make install'
                        sh "touch #{build_ok_fn}"
                    end
                end
            end
        end
        task :run => :build do
            Dir.chdir(shared_dir('stage', 'neovim', 'bin')) do
                publish('nvim', dst: 'bin', mode: 0755)
            end

            link_unless_exists(shared_file('vim', 'config.linux.vim'), File.join(GUBG::mkdir(ENV['HOME'], '.config', 'nvim'), 'init.vim'))
        end
    else
        task :run
    end
end
namespace :fart do
    task :prepare

    task :run
    case os
    when :linux
        task :run do
            Dir.chdir(shared_dir('extern')) do
                git_clone('https://github.com/gfannes', 'FartIT') do
                    sh 'rake define'
                end
            end
        end
    end
end
namespace :exvim do
    task :prepare
    task :build do
        case os
        when :linux
            Dir.chdir(shared_dir('extern')) do
                git_clone('https://github.com/exvim', 'main') do
                    if !File.exist?(build_ok_fn)
                        puts("Building exvim")
                        sh "sh unix/install.sh"
                        sh "touch #{build_ok_fn}"
                    end
                end
            end
        end
    end
    task :run => :build
end
namespace :vix do
    task :prepare
    task :build do
        require('gubg/build/Executable')
        vix = Build::Executable.new('vix')
        vix.add_sources(FileList.new('src/vix/**/*.cpp'))
        vix.build
    end
    task :run => :build
end
