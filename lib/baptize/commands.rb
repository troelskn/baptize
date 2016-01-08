Baptize.application.define_command :list, "Shows list of all available packages" do
  puts "# Packages"
  packages = Baptize::Registry.packages.values
  width = packages.map(&:name).map(&:length).max
  packages.each do |p|
    printf("%-#{width}s  # %s\n",
      p.name,
      p.description)
  end
end

Baptize.application.define_command :policies, "Shows configured policies" do
  puts "# Policies"
  registry = Baptize::Registry
  registry.policies.each do |role, packages|
    puts "#{role}:"
    packages.each do |package|
      puts "  #{package}"
    end
  end
end

Baptize.application.define_command :servers, "Show list of configured servers" do
  puts "# Servers"
  registry = Baptize::Registry
  registry.servers.values.each do |server|
    puts server.inspect
  end
end

Baptize.application.define_command :deploy, "Deploys the configured policies to remote servers" do
  registry = Baptize::Registry
  registry.policies.keys.each do |role|
    registry.for_role role, in: :parallel do |host|
      registry.apply_policy role, host, self
    end
  end
end

Baptize.application.define_command :info, "Shows configuration" do
  Baptize.application.commands[:list].invoke
  puts
  Baptize.application.commands[:policies].invoke
  puts
  Baptize.application.commands[:servers].invoke
end
