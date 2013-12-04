module Capistrano
  module Baptize
    module Plugins
      module Gem

        def install_gem(package_name, options = {})
          cmd = "gem install #{package_name}"
          cmd << " --version '#{options[:version]}'" if options[:version]
          cmd << " --source #{options[:source]}" if options[:source]
          cmd << " --install-dir #{options[:repository]}" if options[:repository]
          cmd << " --no-rdoc --no-ri" unless options[:build_docs]
          cmd << " --http-proxy #{options[:http_proxy]}" if options[:http_proxy]
          cmd << " -- #{options[:build_flags]}" if options[:build_flags]
          run "TERM= #{cmd}"
        end

        def has_gem(package_name, options = {})
          version = options[:version] ? "--version '#{options[:version]}'" : ''
          cmd = "gem list '#{package_name}' --installed #{version} > /dev/null"
          raise VerificationFailure, "Gem #{package_name} not installed" unless remote_assert cmd
        end

      end
    end
  end
end
