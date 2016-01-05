Rake.application.in_namespace('baptize') do

  Rake::Task.define_task(:list) do
    Baptize::Registry.packages.values.each do |package|
      puts [package.name, "\t", package.description].join
    end
  end

  Rake::Task.define_task(:apply) do
    Baptize::Registry.policies.keys.each do |role|
      on roles(role), in: :parallel do |host|
        Baptize::Registry.apply_policy role, host, self
      end
    end
  end

end

Rake::Task.define_task(:default) do
  Rake::Task['baptize:list'].invoke
end
