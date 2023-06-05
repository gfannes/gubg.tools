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
            Supr::Git.collect_sha_and_branch(@root)

            name = @rest.shift()

            fp = @options.output_fp || (name && "#{name}.supr") || 'output.supr'
            scope("Writing state to '#{fp}'", level: 1) do
                str = Supr::Git.to_naft(@root)
                File.write(fp, str)
            end
        end

        def run_load_()
            state_fp = @options.state_fp || ->(name){name && "#{name}.supr"}.(@rest.shift())

            scope("Collecting state from file '#{state_fp}'", level: 1) do |out|
                out.fail("State file '#{state_fp}' does not exist") unless File.exist?(state_fp)

                str = File.read(state_fp)
                @root = Supr::Git.from_naft(str)
                out.(Supr::Git.to_naft(@root), level: 2)

                @root.setup_root_dir(@root_dir)

                Supr::Git.apply(@root, force: @options.force)
            end
        end

        def run_clean_()
            Supr::Git.clean(@root, force: @options.force)
        end

        def run_create_()
            Supr::Git.collect_sha_and_branch(@root)

            branch = @rest.shift()
            error("No branch was specified") unless branch

            Supr::Git.create(@root, branch, where: @options.where, force: @options.force, noop: @options.noop)
        end

        def run_delete_()
            Supr::Git.collect_sha_and_branch(@root)

            branch = @rest.shift()
            error("No branch was specified") unless branch

            Supr::Git.delete(@root, branch, force: @options.force, noop: @options.noop)
        end

        def run_switch_()
            branch = @rest.shift()
            error("No branch was specified") unless branch

            Supr::Git.switch(@root, branch, where: @options.where, continue: @options.continue, j: @options.j)
        end

        def run_pull_()
            Supr::Git.pull(@root, continue: @options.continue, where: @options.where, force: @options.force, noop: @options.noop, j: @options.j)
        end

        def run_push_()
            Supr::Git.push(@root, continue: @options.continue, where: @options.where, force: @options.force, noop: @options.noop, j: @options.j)
        end

        def run_status_()
            Supr::Git.status(@root, where: @options.where)
        end

        def run_run_()
            Supr::Git.run(@root_dir, @rest.map{|e|e.split(' ')})
        end

        def run_diff_()
            difftool = @rest.shift() || ENV['supr_difftool']
            Supr::Git.diff(@root, difftool: difftool, where: @options.where)
        end

        def run_commit_()
            error("No commit message was specified") if @options.rest.empty?()
            msg = @options.rest*"\n"

            Supr::Git.commit(@root, msg, where: @options.where, force: @options.force)
        end

        def run_sync_()
            branch = @rest.shift()
            error("No branch was specified") unless branch

            Supr::Git.sync(@root, branch, where: @options.where, continue: @options.continue, j: @options.j)
        end

        def run_deliver_()
            branch = @rest.shift()
            error("No branch was specified") unless branch

            Supr::Git.deliver(@root, branch, where: @options.where)
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

                        begin
                            @root = Supr::Git.from_naft(state_str)
                            @root.setup_root_dir(@root_dir)

                            debug.("Applying state")
                            Supr::Git.apply(@root, force: @options.force) do |line|
                                client.puts(line)
                            end
                            debug.("Done applying state")

                            cmd = cmd_str.split(' ')

                            debug.("Running command '#{cmd*' '}'")
                            if cmd == %w[stop]
                                out.warning("Received 'stop' command")
                                break
                            else
                                Supr::Git.run(@root_dir, cmd) do |line|
                                    client.puts(line)
                                end
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
                        out.warning("Aborting, client closed connection: #{exc}")
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
