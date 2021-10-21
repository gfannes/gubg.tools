require("optparse")
require("open3")
require("fileutils")
require("rake")
require("set")

module My
	def self.parse_cli_options()
		options = {
			recursive: false,
			with_details: false,
			mode: :master,
			tmp_dir: "/tmp/ghist",
			force: false,
			extensions: Set.new(),
			git_options: [],

			help_text: nil,
		}
		begin
			OptionParser.new do |opts|
				opts.banner = "Usage: ghist [options]"
				opts.on("-h", "--help", "Print this help") { |v| options[:mode] = :help; options[:help] = opts.to_s }
				opts.on("-r", "--recursive", "Recurse over submodules") { |v| options[:recursive] = true }
				opts.on("-d", "--details", "Include details per submodule") { |v| options[:with_details] = true }
				opts.on("-c", "--client", "Run as client") { |v| options[:mode] = :client }
				opts.on("-t", "--tmp FOLDER", "Temporary FOLDER") { |dir| options[:tmp_dir] = dir }
				opts.on("-f", "--force", "Force removal of temporary folder") { |v| options[:force] = true }
				opts.on("-e", "--extension EXT", "Track files with extension (use `cpp`, not `.cpp`)") { |ext| options[:extensions].add(ext) }
				opts.on("-o", "--output FILEPATH", "Output filepath") { |fp| options[:output_fp] = fp }
				opts.on("-X", "--Xgit OPTION", "Pass additional OPTION to git, eg `--since=...` and `--until=...`") { |git_option| options[:git_options] << git_option }
				opts.separator("Developed by Geert Fannes")
			end.parse!

			options[:extensions].freeze() unless options[:extensions].empty?

			raise("Not all CLI arguments could be parsed: #{ARGV}") unless ARGV.empty?
		end
		options
	end

	def self.collect_data(output_fp, git_options)
		cmd = %w[git log --numstat --no-merges -M -C -w --ignore-blank-lines --ignore-submodules] << "--format=[commit](author:%an)(date:%ai)"
		cmd += git_options
		stdout, stderr, status = Open3.capture3(*cmd)
		raise("Could not collect data in #{Dir.pwd}") unless status.success?
		File.write(output_fp, stdout)
	end

	def self.merge_all(data_dir, extensions)
		re_commit = /^\[commit\]\(author:(.+)\)\(date:(.+)\)$/
		re_count = /^(\d+)\t(\d+)\t(.+)$/
		re_rename1 = /^(.+){(.+) => (.+)}$/
		re_rename2 = /^(.+) => (.+)$/

		author__commits = Hash.new{|h,k|h[k] = []}

		Dir.chdir(data_dir) do
			Rake::FileList.new("*").each do |fn|
				File.open(fn) do |fi|
					commit = nil
					fi.each_line do |line|
						if md = re_commit.match(line)
							author, date = md[1], md[2]

							commit = {
								date: date,
								submodule: fn,
								ext__count: Hash.new{|h,k|h[k] = 0},
							}

							author__commits[author] << commit
						elsif md = re_count.match(line)
							added, removed, filepath = md[1].to_i, md[2].to_i, md[3]

							if md = re_rename1.match(filepath)
								filepath = md[1]+md[3]
							elsif md = re_rename2.match(filepath)
								filepath = md[2]
							end

							ext = File.extname(filepath)
							ext = ext[1,ext.size] if ext[0] == "."

							if ext == "tools"
								puts commit
								puts filepath
							end

							extensions.add(ext) unless extensions.frozen?

							commit[:ext__count][ext] += [added, removed].max if extensions.include?(ext)
						end
					end
				end
			end
		end
		author__commits
	end

	def self.stream_tsv(os, author__commits, extensions, with_details)
		os.print("AUTHOR\tSUBMODULE\tTOTAL")
		extensions.each{|ext|os.print("\t#{ext}")}
		os.puts("")

		author__ext__sm__count = {}
		author__commits.each do |author, commits|
			ext__sm__count = Hash.new{|h,ext|h[ext] = Hash.new{|h,sm|h[sm] = 0}}
			commits.each do |commit|
				sm = commit[:submodule]
				commit[:ext__count].each do |ext, count|
					ext__sm__count[ext][sm] += count
				end
			end
			author__ext__sm__count[author] = ext__sm__count
		end

		author__count = Hash.new{|h,author|h[author] = 0}
		author__ext__count = Hash.new{|h,author|h[author] = Hash.new{|h,ext|h[ext] = 0}}
		author__sm__count = Hash.new{|h,author|h[author] = Hash.new{|h,sm|h[sm] = 0}}
		author__sm__ext__count = Hash.new{|h,author|h[author] = Hash.new{|h,sm|h[sm] = Hash.new{|h,ext|h[ext] = 0}}}
		author__ext__sm__count.each do |author, ext__sm__count|
			ext__sm__count.each do |ext, sm__count|
				sm__count.each do |sm, count|
					author__count[author] += count
					author__ext__count[author][ext] += count
					author__sm__count[author][sm] += count
					author__sm__ext__count[author][sm][ext] += count
				end
			end
		end

		authors = author__count.sort_by(&:last).reverse().map{|pair|pair[0]}

		authors.each do |author|
			os.print("#{author}\t*\t#{author__count[author]}")
			extensions.each do |ext|
				os.print("\t#{author__ext__count[author][ext]}")
			end
			os.puts("")
		end
		if with_details
			authors.each do |author|
				author__sm__count[author].sort_by(&:last).reverse().each do |sm, count|
					os.print("#{author}\t#{sm}\t#{count}")
					extensions.each do |ext|
						os.print("\t#{author__sm__ext__count[author][sm][ext]}")
					end
					os.puts("")
				end
			end
		end
	end
end

options = My.parse_cli_options()

tmp_dir = options[:tmp_dir]

case options[:mode]
when :help
	puts(options[:help])
when :master
	if File.exist?(tmp_dir)	
		raise("Temparary folder `#{tmp_dir}` already exists. Use --force to remove it") unless options[:force]
		FileUtils.rm_rf(tmp_dir)
	end
	FileUtils.mkdir_p(tmp_dir)

	#Collect my own data
	My.collect_data(File.join(tmp_dir, "ROOT"), options[:git_options])

	if options[:recursive]
		cmd = %w[git submodule foreach ghist -c -t] << tmp_dir
		cmd += options[:git_options].map{|git_option|["--Xgit", git_option]}.flatten
		stdout, stderr, status = Open3.capture3(*cmd)
		raise("Could not run ghist client in all submodules") unless status.success?
	end

	author__commits = My.merge_all(tmp_dir, options[:extensions])

	if options[:output_fp]
		File.open(options[:output_fp], "w") do |fo|
			My.stream_tsv(fo, author__commits, options[:extensions], options[:with_details])
		end
	else
		My.stream_tsv($stdout, author__commits, options[:extensions], options[:with_details])
	end

	FileUtils.rm_rf(tmp_dir)
when :client
	name = ENV["name"] || File.basename(Dir.pwd)
	My.collect_data(File.join(tmp_dir, name), options[:git_options])
else
	raise("Unknown mode #{mode}")
end
