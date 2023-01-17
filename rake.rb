require("gubg/shared")
include Gubg

here = File.dirname(__FILE__)

namespace :tools do
	task :prepare do
		case os()
		when :linux
			Gubg.chdir(Gubg.home_dir) do
				%i[bash zsh].each do |shell|
					shrc = ".#{shell}rc"
					if !File.read(shrc)["gubg"]
						puts("Installing Gubg environment into #{shrc}. Restart you shell.")
						File.open(shrc, "a") do |fo|
							fo.puts("\n\n#Gubg environment setup")
							fo.puts("export gubg=$HOME/gubg")
							fo.puts("export PATH=$PATH:$gubg/bin")
							fo.puts("source $gubg/bin/all-#{shell}.sh")
						end
					end if File.exist?(shrc)
				end
			end
			sh "git config --global core.excludesfile ~/.gitignore"
		end
		%i[sh git ghist helix kak broot].each do |e|
			Rake::Task["gubg:tools:#{e}:prepare"].invoke()
		end
	end

	namespace :sh do
		task :prepare do
			case os()
			when :linux, :macos
				publish(here, 'src/sh', dst: 'bin', mode: 0755)
				link_unless_exists(shared_file('bin', 'dotinputrc'), Gubg.home_file('.inputrc'))
				publish(here, 'src/ruby', dst: 'bin', mode: 0755){|fn|fn.gsub(/\.rb$/,'')}
			when :windows
				publish(here, 'src/bat', dst: 'bin')
			end
		end
	end
	namespace :helix do
		task :prepare do
			case os()
			when :linux, :macos
				publish(here, 'src/helix', dst: Gubg.home_file('.config/helix'), mode: 0755)
			when :windows
				publish(here, 'src/helix', dst: Gubg.home_file('AppData/Roaming/helix'), mode: 0755)
			end
		end
	end
	namespace :kak do
		task :prepare do
			case os()
			when :linux, :macos
				publish(here, 'src/kak', dst: Gubg.home_file('.config/kak'), mode: 0755)
			end
		end
	end
	namespace :broot do
		task :prepare do
			publish(here, 'src/broot', dst: Gubg.home_file('.config/broot'), mode: 0755)
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
			else raise("Unknown os #{os}")
			end
			Dir.chdir(shared_dir('bin')) do
				print("Creating Q commands:")
				{
					qs: 'git status',
	                # qS: 'git status --porcelain',
	                #qd: 'git diff',
	                #qd: 'git difftool -t meld --ignore-submodules',
	                #qd: 'git difftool -t meld -y --ignore-submodules',
	                #qd: 'git difftool -t diffuse -y --ignore-submodules',
	                #qd: 'git difftool -t kdiff3 -y --ignore-submodules',
	                qd: 'git icdiff',
	                qc: 'git commit -a',
	                qp: 'git pull --rebase',
					qpp: ['git stash', 'git pull --rebase', 'git stash apply'],
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
	            	else raise("Unknown os #{os}")
	            	end
	            	File.open(fn, "w", 0755) do |fo|
	            		print(" #{fn}")
	            		case os
	            		when :linux, :macos then fo.puts(bash)
	            		end
	            		fo.puts([cmd].join("\n")+' '+args)
	            	end
	            end
	            puts()
	        end
	        sh "git config --global diff.tool icdiff"
	        sh "git config --global difftool.prompt false"
	        sh "git config --global difftool.icdiff.cmd \"/usr/bin/icdiff --line-numbers \\$LOCAL \\$REMOTE\""
	    end
	end
	namespace :ghist do
		task :prepare do
			publish(here, 'src/ghist', pattern: "ghist", dst: 'bin', mode: 0755)
			publish(here, 'src/ghist', pattern: "*.rb", dst: 'ruby')
		end
	end
	
	task :install do |t, args|
		require("gubg/build/Cooker")
		cooker = Build::Cooker.new().option("c++.std", 17).output("bin")

		default_recipes = %w[gplot autoq sar naft]
		default_recipes = %w[gplot sar naft]
		recipes = filter_recipes(args, default_recipes)
		cooker.generate(:ninja, *recipes).ninja()
	end
end

namespace :autoq do
    desc "End to end tests"
    task :ee => :build do
        test_cases = (0...2).to_a
        test_cases.each do |tc|
            base = "test/ee/autoq"
            Dir.chdir(Gubg.mkdir(here, base, tc)) do
                case tc
                when 0
                    sh "autoq -h"
                when 1
                    sh "autoq system system.ssv target target.ssv population 100 iteration 200"
                end
            end
        end
    end
end
