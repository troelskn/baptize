module Baptize

  module Plugins

    module Execution

      # logs the command then executes it locally.
      # returns the command output as a string
      def run_locally(cmd)
        if fetch(:dry_run)
          return logger.debug "executing locally: #{cmd.inspect}"
        end
        logger.trace "executing locally: #{cmd.inspect}" if logger
        output_on_stdout = nil
        elapsed = Benchmark.realtime do
          output_on_stdout = `#{cmd}`
        end
        if $?.to_i > 0 # $? is command exit code (posix style)
          raise ArgumentError, "Command #{cmd} returned status code #{$?}"
        end
        logger.trace "command finished in #{(elapsed * 1000).round}ms" if logger
        output_on_stdout
      end

      def remote_execute(*args)
        call_current_ssh_connection :execute, *args
      end

      def remote_capture(*args)
        call_current_ssh_connection :capture, *args
      end

      def remote_assert(command)
        command = Array(command).flatten.map {|c| "#{c} > /dev/null 2> /dev/null" }.join(" && ")
        call_current_ssh_connection :test, command
      end

      private
      def call_current_ssh_connection(action, *args)
        ssh = fetch(:current_ssh_connection)
        old_verbosity = nil
        if fetch(:ssh_verbose)
          old_verbosity = SSHKit.config.output_verbosity
          SSHKit.config.output_verbosity = Logger::DEBUG
        end
        begin
          if fetch(:use_bash)
            args = ["bash -c " + args.join(" ; ").shellescape]
          end
          args.unshift(:sudo) if fetch(:use_sudo)
          ssh.send(action, *args)
        ensure
          SSHKit.config.output_verbosity = old_verbosity if old_verbosity
        end
      end

    end

  end # module Plugins
end # module Baptize
