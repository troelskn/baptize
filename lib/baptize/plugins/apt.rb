module Baptize

  module Plugins

    module Apt

      def apt(packages, options = {})
        command = options[:dependencies_only] ? 'build-dep' : 'install'
        noninteractive = "env DEBCONF_TERSE='yes' DEBIAN_PRIORITY='critical' DEBIAN_FRONTEND=noninteractive"
        packages = Array(packages).flatten.map{|p| p.to_s.shellescape }.join(" ")
        remote_execute "#{noninteractive} apt-get --assume-yes --force-yes --show-upgraded --quiet #{command} #{packages}"
      end

      def has_apt(packages)
        Array(packages).flatten.each do |p|
          raise VerificationFailure, "apt package #{p} not installed" unless remote_assert("dpkg --status #{p.to_s.shellescape} | grep 'ok installed'")
        end
      end

    end

  end # module Plugins
end # module Baptize
