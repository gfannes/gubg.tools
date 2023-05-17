require('supr/options')
require('supr/log')
require('supr/git')

require('socket')

module Supr
    class App
        def initialize()
            @options = Options.new()
        end

        def call()
            set_log_level(@options.verbose_level)
            set_add_time(@options.time)

            if @options.help
                puts(@options.help)
            elsif !@options.rest.empty?()
                verb = @options.rest.shift().to_sym()
                @rest = @options.rest

                toplevel_dir = Supr::Git.toplevel_dir(@options.root_dir)
                @state = Supr::Git::State.new(toplevel_dir: toplevel_dir)

                if %i[collect clean status diff commit branch switch push run sync deliver remote].include?(verb)
                    scope("Collecting state from dir '#{toplevel_dir}'", level: 1) do |out|
                        # We only allow working with a dirty state for specific verbs
                        # Others require an explicit force
                        force = %i[status diff commit clean branch].include?(verb) ? true : @options.force
                        @state.from_dir(force: force)
                    end
                end

                scope("Running verb '#{verb}'", level: 1) do |out|
                    method = "run_#{verb}_".to_sym()
                    out.fail("Unknown verb '#{verb}'") unless self.respond_to?(method, true)

                    self.send(method)
                end
            end
        end

        private
        def run_collect_()
            name = @rest[0]

            @state.name = name

            fp = @options.output_fp || (name && "#{name}.supr") || 'output.supr'
            scope("Writing state to '#{fp}'", level: 1) do
                str = @state.to_naft()
                File.write(fp, str)
            end
        end

        def run_clean_()
            @state.clean(force: @options.force)
        end

        def run_load_()
            name = @rest[0]
            state_fp = @options.state_fp || (name && "#{name}.supr")

            scope("Collecting state from file '#{state_fp}'", level: 1) do |out|
                out.fail("State file '#{state_fp}' does not exist") unless File.exists?(state_fp)
                @state.from_naft(File.read(state_fp))
                @state.apply(force: @options.force)
            end
        end

        def run_branch_()
            branch = @options.branch || @rest[0]
            error("No branch was specified") unless branch

            @state.branch(branch, delete: @options.delete, force: @options.force)
        end

        def run_switch_()
            branch = @options.branch || @rest[0]
            error("No branch was specified") unless branch

            @state.switch(branch, continue: @options.continue)
        end

        def run_push_()
            @state.push(continue: @options.continue)
        end

        def run_run_()
            @state.run(@rest)
        end

        def run_status_()
            @state.status()
        end

        def run_diff_()
            difftool = @options.rest[0]
            @state.diff(difftool)
        end

        def run_commit_()
            error("No commit message was specified") if @options.rest.empty?()
            msg = @options.rest*"\n"
            @state.commit(msg, force: @options.force)
        end

        def run_sync_()
            branch = @options.branch || @rest[0]
            error("No branch was specified") unless branch

            @state.sync(branch, continue: @options.continue)
        end

        def run_deliver_()
            branch = @options.branch || @rest[0]
            error("No branch was specified") unless branch

            @state.deliver(branch)
        end

        def run_serve_()
            any_interface = '0.0.0.0'
            interface = @options.ip || any_interface
            port = @options.port || (@rest[0] && @rest[0].to_i())
            scope("Running TCP server on '#{interface}:#{port}'", level: 1) do |out|
                out.fail("No port was specified") unless port
                server = TCPServer.new(interface, port)
                loop do
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

                    @state.from_naft(state_str)

                    debug.("Applying state")
                    @state.apply(force: @options.force) do |line|
                        client.puts(line)
                    end
                    debug.("Done applying state")

                    begin
                        cmd = cmd_str.split(' ')

                        debug.("Running command '#{cmd*' '}'")
                        @state.run(cmd) do |line|
                            client.puts(line)
                        end
                        debug.("Done running command")
                    rescue Errno::ENOENT => exc
                        client.puts("[Status](code:ENOENT)(msg:#{exc})")
                    rescue Errno::EPIPE => exc
                        out.warning("Aborting, client closed connection")
                    else
                        client.puts("[Status](code:OK)")
                    end

                    client.close()
                end
            end
        end

        def run_remote_()
            ip, port = @options.ip, @options.port
            scope("Running remote command on '#{ip}:#{port}'", level: 1) do |out|
                out.fail("No TCP address was specified") unless ip
                out.fail("No TCP port was specified") unless port
                socket = TCPSocket.new(ip, port)
                socket.puts(@rest*' ')
                socket.puts(@state.to_naft())
                socket.shutdown(Socket::SHUT_WR)
                status_line = nil
                socket.each_line do |line|
                    line = line.chomp().encode('UTF-8')
                    last_line = line
                    out.("🌐 #{line}")
                end
                socket.close()
            end
        end
    end
end
