module Capistrano
  module Baptize

    # Raised by verifiers, if conditions aren't met
    class VerificationFailure < RuntimeError
    end

    class PolicyDefinition
      attr_reader :role, :dependencies

      def initialize(role, parent)
        @role = role
        @dependencies = []
        @parent = parent
      end

      def respond_to?(sym, include_priv = false)
        super || @parent.respond_to?(sym, include_priv)
      end

      def method_missing(sym, *args, &block)
        if @parent.respond_to?(sym)
          @parent.send(sym, *args, &block)
        else
          super
        end
      end

      def full_name
        "baptize:policies:#{role}"
      end

      def requires(*tasks)
        Array(tasks).flatten.each do |name|
          @dependencies << (name.kind_of?(Symbol) ? "baptize:packages:#{name}" : name.to_s)
        end
      end
    end

    class PackageDefinition
      attr_reader :name, :description, :dependencies, :install_block, :verify_block, :before_block, :after_block

      def initialize(name, parent)
        @name = name
        @parent = parent
        @dependencies = []
        @install_block = nil
        @verify_block = nil
        @before_block = nil
        @after_block = nil
      end

      def respond_to?(sym, include_priv = false)
        super || @parent.respond_to?(sym, include_priv)
      end

      def method_missing(sym, *args, &block)
        if @parent.respond_to?(sym)
          @parent.send(sym, *args, &block)
        else
          super
        end
      end

      def full_name
        "baptize:packages:#{name}"
      end

      def description(desc = nil)
        @description = desc unless desc.nil?
        @description
      end
      alias_method :desc, :description

      def requires(*tasks)
        Array(tasks).flatten.each do |name|
          @dependencies << "baptize:packages:#{name}"
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

    module DSL

      def self.packages_installed
        @packages_installed ||= []
      end

      def self.packages_installed=(value)
        @packages_installed = value
      end

      def self.policies
        @policies ||= {}
      end

      def policy(role_names, &block)
        Array(role_names).flatten.each do |role_name|
          if Capistrano::Baptize::DSL.policies[role_name]
            policy = Capistrano::Baptize::DSL.policies[role_name]
            policy.instance_eval &block
          else
            Capistrano::Baptize::DSL.policies[role_name] = PolicyDefinition.new(role_name, self)
            policy = Capistrano::Baptize::DSL.policies[role_name]
            policy.instance_eval &block
            namespace :baptize do
              namespace :policies do
                desc "Configures #{policy.role}"
                task policy.role do
                  logger.info "Applying policy #{policy.role}"
                  # TODO: This is maybe not ideal, as multiple roles would be applied in sequence, not parallel.
                  # Also, I'm not sure if they would be skipped for later roles, if already run for an earlier one
                  Capistrano::Baptize::DSL.packages_installed = []
                  for_roles policy.role do
                    policy.dependencies.each do |task_name|
                      find_and_execute_task(task_name)
                    end
                  end
                end
              end
            end
            after "baptize:install", policy.full_name
          end
        end
      end

      def package(package_name, &block)
        package = PackageDefinition.new(package_name, self)
        package.instance_eval &block
        namespace :baptize do
          namespace :packages do
            desc "[package] #{package.description}" if package.description
            task package.name do
              # Cap doesn't track if a task has already been applied - we need to do this
              unless Capistrano::Baptize::DSL.packages_installed.include? package.name
                Capistrano::Baptize::DSL.packages_installed << package.name
                instance_eval(&package.before_block) if package.before_block
                if package.verify_block
                  logger.debug "Verifying package #{package.name}"
                  already_installed = begin
                                        instance_eval(&package.verify_block)
                                        true
                                      rescue VerificationFailure => err
                                        false
                                      end
                  if already_installed
                    logger.info "Skipping previously installed package #{package.name}"
                  else
                    logger.info "Installing package #{package.name}"
                    instance_eval(&package.install_block)
                    instance_eval(&package.verify_block)
                  end
                elsif package.install_block
                  # logger.important "WARNING: `verify` block not implemented for package #{package.name}."
                  logger.info "Installing package #{package.name}"
                  instance_eval(&package.install_block)
                else
                  # logger.important "WARNING: `install` block not implemented for package #{package.name}."
                  logger.info "Nothing to do for package #{package.name}"
                end
                instance_eval(&package.after_block) if package.after_block
              end
            end
          end
        end
        package.dependencies.each do |task_name|
          before package.full_name, task_name
        end
      end
    end

  end
end

