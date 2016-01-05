module Baptize

  class PackageDefinition
    attr_reader :name, :description, :dependencies, :install_block, :verify_block, :before_block, :after_block

    def initialize(name, execution_scope, registry)
      @name = name
      @execution_scope = execution_scope
      @registry = registry
      @dependencies = []
      @install_block = nil
      @verify_block = nil
      @before_block = nil
      @after_block = nil
    end

    def execute
      unless @registry.packages_executed.include? full_name
        @registry.packages_executed << full_name
        logger.info "Resolving dependencies for #{name}"
        @registry.before(self).each do |dependency|
          logger.debug "--> #{dependency}"
          @registry.resolve_dependency(dependency).tap do |task|
            task.call
          end
        end
        @dependencies.each do |dependency|
          logger.debug "--> #{dependency}"
          @registry.resolve_dependency(dependency).tap do |task|
            task.call
          end
        end
        instance_eval(&before_block) if self.before_block
        if verify_block
          logger.debug "Verifying package #{name}"
          already_installed = begin
                                instance_eval(&verify_block)
                                true
                              rescue VerificationFailure
                                false
                              end
          if already_installed && !ENV['FORCE_INSTALL']
            logger.info "Skipping previously installed package #{name}"
          else
            if already_installed && ENV['FORCE_INSTALL']
              logger.important "Force installing previously installed package #{name}"
            else
              logger.info "Installing package #{name}"
            end
            instance_eval(&install_block)
            instance_eval(&verify_block)
          end
        elsif install_block
          # logger.important "WARNING: `verify` block not implemented for package #{name}."
          logger.info "Installing package #{name}"
          instance_eval(&install_block)
        else
          # logger.important "WARNING: `install` block not implemented for package #{name}."
          logger.info "Nothing to do for package #{name}"
        end
        instance_eval(&after_block) if after_block
        @registry.after(self).each do |dependency|
          @registry.resolve_dependency(dependency).tap do |task|
            task.call
          end
        end
      end
    end

    def respond_to?(sym, include_priv = false)
      super || @execution_scope.any?(sym) || @execution_scope.respond_to?(sym)
    end

    def method_missing(sym, *args, &block)
      if @execution_scope.any?(sym)
        @execution_scope.fetch(sym)
      elsif @execution_scope.respond_to?(sym)
        @execution_scope.send(sym, *args, &block)
      else
        super
      end
    end

    def full_name
      name.to_s
    end

    def description(desc = nil)
      @description = desc unless desc.nil?
      @description
    end
    alias_method :desc, :description

    def requires(*tasks)
      Array(tasks).flatten.each do |name|
        @dependencies << name
      end
    end

    def before(&block)
      @before_block = block
    end

    def after(&block)
      @after_block = block
    end

    def install(&block)
      @install_block = block
    end

    def verify(&block)
      @verify_block = block
    end
  end

end # module Baptize
