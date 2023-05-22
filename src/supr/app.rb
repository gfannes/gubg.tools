require('supr/options')
require('supr/log')
require('supr/git')
require('supr/git/module')

require('socket')

module Supr
    class App
        def initialize()
            @options = Options.new()
            @default_port = 8128
        end

        def call()
            set_log_level(@options.verbose_level)
            set_add_time(@options.time)

            verb = ->(verb){verb && verb.to_sym()}.(@options.rest.shift())

            if @options.print_help || !verb
                puts(@options.help_msg)
            else
                @rest = @options.rest

                @root_dir = Git::Env.new(@options.root_dir).root_dir()

                @root = Supr::Git::Module.load_from(@root_dir)

                scope("Running verb '#{verb}'", level: 1) do |out|
                    method = "run_#{verb}_".to_sym()
                    out.fail("Unknown verb '#{verb}'") unless self.respond_to?(method, true)

                    self.send(method)
                end
            end
        end

        private
        def run_collect_()
            name = @rest.shift()

            @root.name = name

            Supr::Git.collect_sha_and_branch(@root)

            fp = @options.output_fp || (name && "#{name}.supr") || 'output.supr'
            scope("Writing state to '#{fp}'", level: 1) do
                str = Supr::Git.to_naft(@root)
                File.write(fp, str)
            end
        end

        def run_clean_()
            Supr::Git.clean(@root, force: @options.force)
        end

        def run_load_()
            state_fp = @options.state_fp || ->(name){name && "#{name}.supr"}.(@rest.shift())

            scope("Collecting state from file '#{state_fp}'", level: 1) do |out|
                out.fail("State file '#{state_fp}' does not exist") unless File.exists?(state_fp)

                str = File.read(state_fp)
                @root = Supr::Git.from_naft(str)
                out.(Supr::Git.to_naft(@root), level: 2)

                Supr::Git.apply(@root, force: @options.force)
            end
        end

        def run_create_()
            branch = @options.branch || @rest.shift()
            error("No branch was specified") unless branch

            where = @rest.shift()

            Supr::Git.create(@root, branch, delete: @options.delete, where: where, force: @options.force, noop: @options.noop)
        end

        def run_switch_()
            branch = @options.branch || @rest.shift()
            error("No branch was specified") unless branch

            Supr::Git.switch(@root, branch, continue: @options.continue)
        end

        def run_pull_()
            where = @rest.shift()
            Supr::Git.pull(@root, continue: @options.continue, where: where, force: @options.force, noop: @options.noop)
        end

        def run_push_()
            where = @rest.shift()
            Supr::Git.push(@root, continue: @options.continue, where: where, noop: @options.noop)
        end

        def run_run_()
            Supr::Git.run(@root_dir, @rest)
        end

        def run_status_()
            Supr::Git.status(@root)
        end

        def run_diff_()
            difftool = @rest.shift() || ENV['supr_diff']
            Supr::Git.diff(@root, difftool: difftool)
        end

        def run_commit_()
            error("No commit message was specified") if @options.rest.empty?()
            msg = @options.rest*"\n"
            Supr::Git.commit(@root, msg, force: @options.force)
        end

        def run_sync_()
            branch = @options.branch || @rest.shift()
            error("No branch was specified") unless branch

            Supr::Git.sync(@root, branch, continue: @options.continue)
        end

        def run_deliver_()
            branch = @options.branch || @rest.shift()
            error("No branch was specified") unless branch

            Supr::Git.deliver(@root, branch)
        end

        def run_serve_()
            any_interface = '0.0.0.0'
            interface = @options.ip || any_interface
            port = (@options.port || @rest.shift() || @default_port).to_i()
            scope("Running TCP server on '#{interface}:#{port}'", level: 1) do |out|
                out.fail("No port was specified") unless port
                server = TCPServer.new(interface, port)
                loop do
                    begin
                        client = out.("Waiting for a connection") {server.accept()}

                        debug = ->(msg){
                            client.puts("[Debug](msg:#{msg})")
                        }

                        debug.("Hello")

                        cmd_str = out.("Reading command") do
                            str = client.readline().chomp()
                            out.(str)
                            str
                        end

                        state_str = out.("Reading repo state") do
                            # Read all data, until the client closes its write-end of the connection
                            str = client.read()
                            out.(str)
                            str
                        end

                        @root = Supr::Git.from_naft(state_str)

                        debug.("Applying state")
                        Supr::Git.apply(@root, force: @options.force) do |line|
                            client.puts(line)
                        end
                        debug.("Done applying state")

                        begin
                            cmd = cmd_str.split(' ')

                            debug.("Running command '#{cmd*' '}'")
                            Supr::Git.run(@root, cmd) do |line|
                                client.puts(line)
                            end
                            debug.("Done running command")
                        rescue Errno::ENOENT => exc
                            client.puts("[Status](code:ENOENT)(msg:#{exc})")
                        rescue RuntimeError => exc
                            client.puts("[Status](code:RuntimeError)(msg:#{exc})")
                        else
                            client.puts("[Status](code:OK)")
                        end
                    rescue Errno::EPIPE => exc
                        out.warning("Aborting, client closed connection")
                    ensure
                        client.close()
                    end
                end
            end
        end

        def run_remote_()
            Supr::Git.collect_sha_and_branch(@root)

            ip = @options.ip || @rest.shift()
            port = @options.port || @default_port
            scope("Running remote command on '#{ip}:#{port}'", level: 1) do |out|
                out.fail("No TCP address was specified") unless ip
                out.fail("No TCP port was specified") unless port
                socket = TCPSocket.new(ip, port)
                socket.puts(@rest*' ')
                socket.puts(Supr::Git.to_naft(@root))
                socket.shutdown(Socket::SHUT_WR)
                status_line = nil
                socket.each_line do |line|
                    line = line.chomp().encode('utf-8', invalid: :replace, undef: :replace, replace: '?')
                    last_line = line
                    out.("🌐 #{line}")
                end
                socket.close()
            end
        end
    end
end
