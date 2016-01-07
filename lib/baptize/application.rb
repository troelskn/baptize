module Baptize
  class Application < Rake::Application

    def initialize
      super
      @rakefiles = %w(bapfile Bapfile bapfile.rb Bapfile.rb)
      Rake.application = self
      require 'baptize/rake'
    end

    def name
      "baptize"
    end

    def load_rakefile
      super
      standard_exception_handling do
        in_namespace :packages do
          Baptize::Registry.packages.values.each do |package|
            @last_description = package.description
            define_task(Rake::Task, package.name.to_s) do
              puts "Invoke package: #{package.name}"
              Baptize::Registry.policies.keys.each do |role|
                on roles(role), in: :parallel do |host|
                  Baptize::Registry.execution_scope.set :current_host, host
                  Baptize::Registry.execution_scope.set :current_ssh_connection, ssh_connection
                  package.execute
                end
              end
            end
          end
        end
      end
    end

    def sort_options(options)
      super.push(version, dry_run, roles)
    end

    def handle_options
      options.rakelib = ['rakelib']
      options.trace_output = $stderr

      OptionParser.new do |opts|
        opts.banner = "Baptize prepares your servers"
        opts.separator ""
        opts.separator "Show available tasks:"
        opts.separator "    bundle exec baptize -T"
        opts.separator ""
        opts.separator "Invoke (or simulate invoking) a task:"
        opts.separator "    bundle exec baptize [--dry-run] TASK"
        opts.separator ""
        opts.separator "Advanced options:"

        opts.on_tail("-h", "--help", "-H", "Display this help message.") do
          puts opts
          exit
        end

        standard_rake_options.each { |args| opts.on(*args) }
        opts.environment('RAKEOPT')
      end.parse!
    end


    def display_error_message(ex)
      unless options.backtrace
        if (loc = Rake.application.find_rakefile_location)
          whitelist = (@imported.dup << loc[0]).map{|f| File.absolute_path(f, loc[1])}
          pattern = %r@^(?!#{whitelist.map{|p| Regexp.quote(p)}.join('|')})@
          Rake.application.options.suppress_backtrace_pattern = pattern
        end
        trace "(Backtrace restricted to imported tasks)"
      end
      super
    end

    private

    def version
      ['--version', '-V',
       "Display the program version.",
       lambda { |_value|
         require 'capistrano/version'
         puts "Baptize Version: #{Baptize::VERSION} (Capistrano Version: #{Capistrano::VERSION}, Rake Version: #{RAKEVERSION})"
         exit
       }
      ]
    end

    def dry_run
      ['--dry-run', '-n',
       "Do a dry run without executing actions",
       lambda { |_value|
         raise "TODO: Port this"
         Configuration.env.set(:sshkit_backend, SSHKit::Backend::Printer)
       }
      ]
    end

    def roles
      ['--roles ROLES', '-r',
       "Run SSH commands only on hosts matching these roles",
       lambda { |value|
         raise "TODO: Port this"
         Configuration.env.add_cmdline_filter(:role, value)
       }
      ]
    end

  end
end
