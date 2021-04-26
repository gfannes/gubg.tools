require_relative("../gubg.build/bootstrap.rb")
require("gubg/shared")
include GUBG

home_dir = case os
           when :windows then "#{ENV['HOMEDRIVE']}#{ENV['HOMEPATH']}"
           else ENV["HOME"] end

task :default do
    sh "rake -T"
end

task :clean do
    rm_rf '.cache'
end

desc "Prepare this module: install all scripts"
task :prepare do
    case os
    when :linux
        Dir.chdir(home_dir) do
            if !File.read(".bashrc")["gubg"]
                puts("Installing GUBG environment into .bashrc. Restart you shell.")
                File.open(".bashrc", "a") do |fo|
                    fo.puts("\n\n#GUBG environment setup")
                    fo.puts("export gubg=$HOME/gubg")
                    fo.puts("export PATH=$PATH:$gubg/bin")
                    fo.puts("export RUBYLIB=$gubg/ruby")
                end
            end
        end
    end
    (%w[bash bat kak vim neovim git tmux ccls]).each do |e|
        Rake::Task["#{e}:prepare"].invoke
    end
end

desc "Run this module: build all apps"
task :run do
    apps = %w[fart vix neovim exvim]
    apps = %w[fart vix exvim]
    apps = %w[fart vim vix exvim ccls]
    apps.each do |e|
        Rake::Task["#{e}:run"].invoke
    end
end

build_ok_fn = 'gubg.build.ok'

namespace :bash do
    task :prepare do
        case os
        when :linux, :macos
            publish('src/bash', dst: 'bin', mode: 0755)
            link_unless_exists(shared_file('bin', 'dotinputrc'), File.join(home_dir, '.inputrc'))
            publish('src/ruby', dst: 'bin', mode: 0755){|fn|fn.gsub(/\.rb$/,'')}
        end
    end
end
namespace :bat do
    task :prepare do
        case os
        when :windows
            publish('src/bat', dst: 'bin')
            generated_dir = "generated/src/bat"
            Dir.chdir(GUBG::mkdir(generated_dir)) do
                File.open("gg.bat", "w") do |fo|
                    fo.puts("set gubg=#{ENV['gubg']}")
                    fo.puts("set neovim_exe=\"#{home_dir}\\software\\Neovim\\bin\\nvim-qt.exe\"")
                    fo.puts("%neovim_exe% --maximized %1")
                end
            end
            publish(generated_dir, dst: 'bin')
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
        when :linux, :macos
            publish('src/vim/snippets', pattern: '*', dst: "#{ENV['HOME']}/.config/nvim/gubg_snippets")
        when :windows
            #Needed for vim backup files
            GUBG::mkdir("C:/temp")

            Dir.chdir(GUBG::mkdir("#{home_dir}\\AppData\\Local\\nvim")) do
                File.open("init.vim", "w") do |fo|
                    puts "Writing init.vim"
                    gubg_dir = ENV['gubg']
                    fo.puts("source #{gubg_dir}/vim/nvim.windows.vim")
                end
            end
        end
    end
    task :run do
        if false
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
                when :windows, :macos
                else raise("Unknown os #{os}") end
                # git_clone('https://github.com/Frydac', 'vim-tree')
                git_clone('https://github.com/Frydac', 'vim-auro')
                git_clone('https://github.com/mileszs', 'ack.vim')
                git_clone('https://github.com/tpope', 'vim-commentary')
                git_clone('https://github.com/rking', 'ag.vim')
                git_clone('https://github.com/tpope', 'vim-fugitive')
                git_clone('https://github.com/pangloss', 'vim-javascript')
                git_clone('https://github.com/vim-scripts', 'SearchComplete')
                git_clone('https://github.com/leafgarland', 'typescript-vim')
                git_clone('https://github.com/ctrlpvim', 'ctrlp.vim')
                git_clone('https://github.com/lyuts', 'vim-rtags')
            end
        end
    end
end
namespace :kak do
    task :prepare do
        publish('src', pattern: 'kak/*', dst: "#{home_dir}/.config")
    end
    task :run do
    end
end
namespace :ccls do
    task :prepare do
      case os
      when :linux
        GUBG.publish("src/coc/settings.json", dst: home_dir){"#{home_dir}/.config/nvim/coc-settings.conf"}
        GUBG.publish("src/coc/solargraph.yml", dst: home_dir){"#{home_dir}/aa/.solargraph.yml"}
      end
    end
    task :run do
        Dir.chdir(shared_dir('gubg.tools', 'extern')) do
            case os
            when :linux
                #Depends on `llvm` and `llvm-libs` for arch
                git_clone('https://github.com/MaskRay', 'ccls') do
                    if !File.exist?(build_ok_fn)
                        sh 'cmake -GNinja -H. -BRelease'
                        sh 'cmake --build Release -- -j 8'
                        sh "touch #{build_ok_fn}"
                    end
                end
            when :windows, :macos
            else raise("Unknown os #{os}") end
        end
    end
end
namespace :git do
    task :prepare do
        bash = nil
        args = case os
               when :linux, :macos
                   bash = "\#!"+`which bash`
                   '$1 $2 $3 $4 $5'
               when :windows then '%1 %2 %3 %4 %5'
               else raise("Unknown os #{os}") end
        Dir.chdir(shared_dir('bin')) do
            {
                qs: 'git status',
                #qd: 'git diff',
                #qd: 'git difftool -t meld --ignore-submodules',
                qd: 'git difftool -t meld -y --ignore-submodules',
                #qd: 'git difftool -t diffuse -y --ignore-submodules',
                #qd: 'git difftool -t kdiff3 -y --ignore-submodules',
                qc: 'git commit -a',
                qp: 'git pull --rebase',
                qq: 'git push',
                ql: 'git log -n 5',
                qm: ['git checkout master', 'git branch -d'],
                qb: 'git checkout -b',
                qx: 'git branch -d',
            }.each do |fn, cmd|
                fn = case os
                     when :linux, :macos then fn.to_s
                     when :windows
                         cmd = "git diff --ignore-submodules" if fn == :qd
                         "#{fn}.bat"
                     else raise("Unknown os #{os}") end
                File.open(fn, "w", 0755) do |fo|
                    puts("creating #{fn}")
                    case os
                    when :linux, :macos then fo.puts(bash)
                    end
                    fo.puts([cmd].join("\n")+' '+args)
                end unless File.exist?(fn)
            end
        end
        sh "git config --global diff.tool icdiff"
        sh "git config --global difftool.prompt false"
        sh "git config --global difftool.icdiff.cmd \"/usr/bin/icdiff --line-numbers \\$LOCAL \\$REMOTE\""
    end
end

namespace :neovim do
    task :prepare do
        case os
        when :linux, :macos
            fn = "#{home_dir}/.config/nvim/init.vim"
            unless File.exist?(fn)
                GUBG.mkdir(File.dirname(fn))
                puts("Writing initial neovim init file to #{fn}")
                File.open(fn, "w") do |fo|
                    fo.puts("source $gubg/vim/nvim.linux.vim")
                end
            end

            #TODO: move this to actual files
            fn = "#{home_dir}/.config/nvim/ginit.vim"
            unless File.exist?(fn)
                GUBG.mkdir(File.dirname(fn))
                puts("Writing initial neovim graphical init file to #{fn}")
                File.open(fn, "w") do |fo|
                    fo.puts("GuiFont Hack:h12")
                end
            end

            profile_fn = "#{home_dir}/.profile"
            if File.exist?(profile_fn)
                found = false
                File.open(profile_fn, "r") do |fi|
                    fi.each_line do |line|
                        found = true if line[/^export NVIM_LISTEN_ADDRESS=/]
                    end
                end
                unless found
                    File.open(profile_fn, "a") do |fo|
                        fo.puts("")
                        fo.puts("# Added by gubg.tools")
                        fo.puts("export NVIM_LISTEN_ADDRESS=/tmp/nvimsocket")
                        puts("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
                        puts("You have to re-login for this setting to have effect")
                        puts("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
                    end
                end
            end
        end
    end

    task :run
end
namespace :fart do
    task :prepare

    task :run
    case os
    when :linux
        task :run do
            Dir.chdir(shared_dir('extern')) do
                git_clone('https://github.com/gfannes', 'FartIT') do
                    sh 'rake prepare run'
                end
            end
        end
    end
end
namespace :tmux do
    task :prepare do
        GUBG.publish("src/tmux/conf", dst: home_dir){"#{home_dir}/.tmux.conf"}
        Dir.chdir(GUBG.mkdir("#{home_dir}/.tmux/plugins")) do
            git_clone('https://github.com/tmux-plugins', 'tpm') do
            end
        end
    end
    task :run do
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
        case os
        when :linux, :macos
            require('gubg/build/Executable')
            vix = Build::Executable.new('vix')
            vix.add_sources(FileList.new('src/vix/**/*.cpp'))
            vix.build
        end
    end
    task :run => :build
end
