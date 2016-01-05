module Baptize

  module DSL
    def package(package_name, &config_block)
      Registry.define_package(package_name, &config_block)
    end

    def policy(role, *packages)
      Registry.define_policy role, [packages].flatten
    end
  end # module DSL

end # module Baptize
