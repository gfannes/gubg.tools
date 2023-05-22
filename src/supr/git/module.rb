require('pathname')

module Supr
    module Git

        # Must work without running 'git'
        class Module
            # Info from .gitmodules file
            attr_accessor(:name)
            attr_accessor(:path)
            attr_accessor(:url)
            attr_accessor(:sync_branch) # branch

            attr_accessor(:root_absdir)
            attr_accessor(:parent_absdir)
            attr_accessor(:sha)
            attr_accessor(:my_branch)

            attr_accessor(:submodules)

            def self.load_from(root_absdir)
                recurse = ->(parent_absdir, dst_ary) do
                    Git.parse_modules_file(File.join(parent_absdir, '.gitmodules')).each do |h|
                        my_absdir = File.join(parent_absdir, h[:path])
                        mod = Module.new(my_absdir, **h, root_absdir: root_absdir, parent_absdir: parent_absdir)
                        dst_ary << mod

                        recurse.(my_absdir, mod.submodules)
                    end
                end

                root = Module.new(root_absdir, root_absdir: root_absdir)
                recurse.(root_absdir, root.submodules)

                root
            end

            def initialize(my_absdir, name: nil, path: nil, url: nil, sync_branch: nil, root_absdir: nil, parent_absdir: nil, sha: nil, my_branch: nil)
                @name = name
                @path = path
                @url = url
                @sync_branch = sync_branch

                @root_absdir = root_absdir
                @parent_absdir = parent_absdir || @root_absdir
                @my_branch = my_branch

                @sha = sha

                @submodules = []
            end

            def filepath(*parts)
                File.join([@parent_absdir, @path, *parts].flatten().compact())
            end

            def has_submodules?()
                !@submodules.empty?()
            end

            def each(&block)
                block.(self)
                @submodules.each do |sm|
                    sm.each(&block)
                end
            end

            def to_s()
                Pathname.new(filepath()).relative_path_from(@root_absdir).to_s()
            end
            
        end

        def self.parse_modules_file(fp)
            ary = []

            if File.exist?(fp)
                re_submodule = /\[submodule\s+"(.+)"\]/
                re_path = /\s*path\s*=\s*(.+)/
                re_url = /\s*url\s*=\s*(.+)/
                re_branch = /\s*branch\s*=\s*(.+)/

                content = File.read(fp)
                content.each_line do |line|
                    line.chomp!()
                    if md = re_submodule.match(line)
                        ary << {name: md[1]}
                    elsif md = re_path.match(line)
                        ary[-1][:path] = md[1]
                    elsif md = re_url.match(line)
                        ary[-1][:url] = md[1]
                    elsif md = re_branch.match(line)
                        ary[-1][:sync_branch] = md[1]
                    else
                        error("Could not parse line '#{line}' from '#{fp}'")
                    end
                end
            end

            ary
        end

    end
end
