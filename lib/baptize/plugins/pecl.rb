module Capistrano
  module Baptize
    module Plugins
      module Pecl

        def pecl(package_name, options = {})
          package_version = options[:version]
          if package_version
            run "TERM= pecl install --alldeps #{package_name.shellescape}-#{package_version.shellescape}"
          else
            run "TERM= pecl install --alldeps #{package_name.shellescape}"
          end
          ini_file = ! options[:ini_file].nil?
          if ini_file
            if ini_file.is_a?(String)
              text = ini_file
            elsif ini_file.is_a?(Hash) && ini_file[:content]
              text = ini_file[:content]
            else
              text = "extension=#{package_name}.so"
            end
            if ini_file.is_a?(Hash) && ini_file[:path]
              path = ini_file[:path]
            else
              path = "/etc/php5/conf.d/#{package_name}.ini"
            end
            put(text, path)
          end
        end

        def has_pecl(package_name, options = {})
          package_version = options[:version]
          if package_version
            raise VerificationFailure, "PECL package #{package_name}-#{package_version} not installed" unless remote_assert "TERM= pecl list | grep \"^#{package_name.shellescape}\\\\s*#{package_version.shellescape}\""
          else
            raise VerificationFailure, "PECL package #{package_name} not installed" unless remote_assert "TERM= pecl list | grep \"^#{package_name.shellescape}\\\\s\""
          end
        end

      end
    end
  end
end
