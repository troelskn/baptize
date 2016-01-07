module Baptize

  module DSL
    include Baptize::Plugins::Env

    def package(package_name, &config_block)
      Registry.define_package(package_name, &config_block)
    end

    def policy(role, *packages)
      Registry.define_policy role, [packages].flatten
    end

    def server(role, host, options = {})
      Registry.define_server(role, host, options)
    end
  end # module DSL

end # module Baptize
