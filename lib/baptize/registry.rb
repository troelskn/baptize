module Baptize

  module Registry

    def self.plugins
      @plugins ||= []
    end

    def self.execution_scope
      unless @execution_scope
        @execution_scope = ExecutionScope.new
        plugins.each do |plugin_module|
          (class << @execution_scope ; self ; end).send(:include, plugin_module)
        end
      end
      @execution_scope
    end

    def self.logger
      @logger ||= ::Logger.new(STDOUT)
    end

    def self.packages
      @packages ||= {}
    end

    def self.packages_executed
      @packages_executed ||= []
    end

    def self.before(subject_name, other_task=nil, &block)
      @befores ||= {}
      @befores[subject_name] ||= []
      if other_task
        task = packages[other_task] if other_task.kind_of?(String)
        raise "Didn't find a package by that name" if task.nil?
        @befores[subject_name] << task.method(:execute)
      elsif block_given?
        @befores[subject_name] << block
      end
      @befores[subject_name]
    end

    def self.after(subject_name, other_task=nil, &block)
      @afters ||= {}
      @afters[subject_name] ||= []
      if other_task
        task = packages[other_task] if other_task.kind_of?(String)
        raise "Didn't find a package by that name" if task.nil?
        @afters[subject_name] << task.method(:execute)
      elsif block_given?
        @afters[subject_name] << block
      end
      @afters[subject_name]
    end

    def self.define_package(package_name, &config_block)
      package = PackageDefinition.new(package_name, self.execution_scope, self)
      packages[package.full_name] = package
      package.instance_eval(&config_block)
      if ENV['SKIP_DEPENDENCIES']
        before package.full_name do
          logger.important "Skipping dependencies for package #{package.name}"
        end
      else
        package.dependencies.each do |task_name|
          before package.full_name, task_name
        end
      end
    end

    def self.policies
      @policies ||= {}
    end

    def self.define_policy(role, package_names)
      policies[role.to_sym] = package_names.map(&:to_s)
    end

    def self.apply_policy(role, host, ssh_connection)
      execution_scope.set :current_host, host
      execution_scope.set :current_ssh_connection, ssh_connection
      policies[role.to_sym].each do |package_name|
        raise "No package '#{package_name}'" unless packages[package_name]
        packages[package_name].execute
      end
    end

  end # module Registry

end # module Baptize
