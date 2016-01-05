require 'capistrano/dsl/env'

module Baptize
  module Plugins
    module Env

      include Capistrano::DSL::Env

      def respond_to?(sym, include_priv = false)
        super || any?(sym)
      end

      def method_missing(sym, *args, &block)
        if any?(sym)
          fetch(sym)
        else
          super
        end
      end

    end

  end # module Plugins
end # module Baptize
