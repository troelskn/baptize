module Baptize
  module Plugins
    module Env

      def any?(key)
        value = fetch(key)
        if value && value.respond_to?(:any?)
          value.any?
        else
          !fetch(key).nil?
        end
      end

      def set(key, value=nil, &block)
        config[key] = block || value
      end

      def set_if_empty(key, value=nil, &block)
        set(key, value, &block) unless config.has_key? key
      end

      def delete(key)
        config.delete(key)
      end

      def fetch(key, default=nil, &block)
        value = fetch_for(key, default, &block)
        while callable_without_parameters?(value)
          value = set(key, value.call)
        end
        return value
      end

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

      private

      def config
        @@config ||= Hash.new
      end

      def fetch_for(key, default, &block)
        if block_given?
          config.fetch(key, &block)
        else
          config.fetch(key, default)
        end
      end

      def callable_without_parameters?(x)
        x.respond_to?(:call) && ( !x.respond_to?(:arity) || x.arity == 0)
      end

    end

  end # module Plugins
end # module Baptize
