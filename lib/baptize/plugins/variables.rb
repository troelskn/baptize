module Baptize

  module Plugins

    module Variables

      def set(name, value)
        @variables ||= {}
        @variables[name.to_sym] = value
      end

      def fetch(name)
        if @variables
          value = @variables[name.to_sym]
          if value.kind_of?(Proc)
            value.call
          else
            value
          end
        end
      end

      def respond_to?(sym, include_priv = false)
        super || (@variables && @variables[sym])
      end

      def method_missing(sym, *args, &block)
        if @variables && @variables[sym]
          fetch(sym)
        else
          super
        end
      end

    end

  end # module Plugins
end # module Baptize
