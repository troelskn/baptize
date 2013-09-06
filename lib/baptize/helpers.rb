module Capistrano
  module Baptize

    module Helpers
      def asset_path(asset)
        File.join(fetch(:assets_path), asset)
      end

      def remote_assert(command)
        results = []
        pipeline = Array(command).flatten.map {|c| "#{c} > /dev/null 2> /dev/null ; if [ $? -eq 0 ] ; then echo -n 'true' ; else echo -n 'false' ; fi" }.join(" ; ")
        invoke_command(pipeline) do |ch, stream, out|
          results << (out == 'true')
        end
        results.all?
      end

      # logs the command then executes it locally.
      # returns the command output as a string
      def run_locally(cmd)
        if dry_run
          return logger.debug "executing locally: #{cmd.inspect}"
        end
        logger.trace "executing locally: #{cmd.inspect}" if logger
        output_on_stdout = nil
        elapsed = Benchmark.realtime do
          output_on_stdout = `#{cmd}`
        end
        if $?.to_i > 0 # $? is command exit code (posix style)
          raise Capistrano::LocalArgumentError, "Command #{cmd} returned status code #{$?}"
        end
        logger.trace "command finished in #{(elapsed * 1000).round}ms" if logger
        output_on_stdout
      end

      def current_role
        ENV['ROLES'].to_sym
      end

      def load_configuration(environment)
        top.instance_eval do
          if environment == :all
            Dir.glob("#{capistrano_path}/config/**/*.rb").each do |conf|
              load(conf)
            end
          else
            Dir.glob("#{capistrano_path}/config/#{environment}.rb").each do |conf|
              load(conf)
            end
            Dir.glob("#{capistrano_path}/config/#{environment}/**/*.rb").each do |conf|
              load(conf)
            end
          end
        end
      end

      def md5_of_file(path, md5)
        remote_assert "test $(md5sum #{path.shellescape} | cut -f1 -d' ') = #{md5.shellescape}"
      end

      def escape_sed_arg(s)
        s.gsub("'", "'\\\\''").gsub("\n", '\n').gsub("/", "\\\\/").gsub('&', '\\\&')
      end

      def replace_text(pattern, replacement, path)
        run "sed -i 's/#{escape_sed_arg(pattern)}/#{escape_sed_arg(replacement)}/g' #{path.shellescape}"
      end

      def render(path, locals = {})
        require 'erb'
        require 'ostruct'
        ERB.new(File.read(path)).result(OpenStruct.new(locals).instance_eval { binding })
      end

    end

  end
end
