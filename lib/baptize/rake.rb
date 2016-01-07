Rake::Task.define_task(:list) do
  puts "# Packages"
  packages = Baptize::Registry.packages.values
  width = packages.map(&:name).map(&:length).max
  packages.each do |p|
    printf("%-#{width}s  # %s\n",
      p.name,
      p.description)
  end
end

Rake::Task.define_task(:policies) do
  puts "# Policies"
  registry = Baptize::Registry
  registry.policies.each do |role, packages|
    puts "#{role}:"
    packages.each do |package|
      puts "  #{package}"
    end
  end
end

Rake::Task.define_task(:servers) do
  puts "# Servers"
  registry = Baptize::Registry
  registry.servers.values.each do |server|
    puts server.inspect
  end
end

Rake::Task.define_task(:apply) do
  registry = Baptize::Registry
  registry.policies.keys.each do |role|
    registry.for_role role, in: :parallel do |host|
      registry.apply_policy role, host, self
    end
  end
end

Rake::Task.define_task(:default) do
  Rake::Task['list'].invoke
  puts
  Rake::Task['policies'].invoke
  puts
  Rake::Task['servers'].invoke
end
