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

    def self.has_package?(package_name)
      !! @packages[package_name]
    end

    def self.packages_executed
      @packages_executed ||= []
    end

    def self.before(subject_name, other_task=nil, &block)
      @befores ||= {}
      @befores[subject_name] ||= []
      if other_task
        @befores[subject_name] << other_task
      elsif block_given?
        @befores[subject_name] << block
      end
      @befores[subject_name]
    end

    def self.after(subject_name, other_task=nil, &block)
      @afters ||= {}
      @afters[subject_name] ||= []
      if other_task
        @afters[subject_name] << other_task
      elsif block_given?
        @afters[subject_name] << block
      end
      @afters[subject_name]
    end

    def self.resolve_dependency(mixed)
      if mixed.kind_of?(String) || mixed.kind_of?(Symbol)
        task = packages[mixed.to_s]
        raise "Didn't find a package by that name: '#{mixed}'" if task.nil?
        task.method(:execute)
      elsif mixed.kind_of? PackageDefinition
        mixed.method(:execute)
      else
        mixed
      end
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

    def self.apply_policy(role, options={})
      ssh_for_role role do |host, ssh_for_role|
        policies[role.to_sym].each do |package_name|
          if options[:package].nil? || package_name.to_sym == options[:package].to_sym
            raise "No package '#{package_name}'" unless packages[package_name]
            packages[package_name].execute(force: options[:force])
          end
        end
      end
    end

    def self.servers
      @servers ||= {}
    end

    def self.define_server(role, host, options = {})
      role = role.to_sym
      servers[host] = options.merge(hostname: host)
      servers[host][:roles] ||= []
      servers[host][:roles] << role unless servers[host][:roles].include?(role)
      servers[host]
    end

    def self.servers_for_role(role)
      role = role.to_sym
      host_columns = [:password, :hostname, :port, :user, :key, :ssh_options]
      servers.values
      .select do |server|
        server[:roles].include?(role)
      end.map do |server|
        server.select {|k,v| host_columns.include?(k) }
      end
    end

    def self.for_role(role, options={}, &block)
      subset_copy = Marshal.dump(servers_for_role(role))
      SSHKit::Coordinator.new(Marshal.load(subset_copy)).each(options, &block)
    end

    def self.ssh_for_role(role, &block)
      registry = self
      for_role role, in: :parallel do |host|
        registry.execution_scope.set :current_host, host
        registry.execution_scope.set :current_ssh_connection, self
        block.call
      end
    end

  end # module Registry

end # module Baptize

=begin

    def role(name, hosts, options={})
      servers.add_role(name, hosts, options)
    end

    def roles(*names)
      servers.roles_for(names.flatten)
    end

    def servers
      @servers ||= Servers.new
    end

    def on(hosts, options={}, &block)
      subset_copy = Marshal.dump(Configuration.env.filter(hosts))
      SSHKit::Coordinator.new(Marshal.load(subset_copy)).each(options, &block)
    end

=end
