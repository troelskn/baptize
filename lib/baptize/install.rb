module Capistrano
  module Baptize

    # Defines all baptize top-level tasks
    def self.install(scope)
      scope.instance_eval do
        set(:root_path) { File.expand_path(Dir.pwd) }
        set(:capistrano_path) { "#{root_path}/capistrano" }

        # Can't run this here, since Capfile might want to redefine
        # load_configuration :roles

        namespace :baptize do

          desc "Loads baptize configuration files"
          task :load_configuration do
            top.instance_eval do
              top.load_configuration :baptize
              default_run_options[:shell] = 'sudo bash' if fetch(:use_sudo, true)
            end
          end

          task :default do
            load_configuration
            install
          end

          desc "Configures all available policies"
          task :install do ; end

          namespace :policies do
            desc "List available policies"
            task :default do
              load_configuration
              logger.info "Available policies:"
              tasks.flatten.each do |x|
                if x.kind_of?(Capistrano::TaskDefinition) && x.fully_qualified_name != "baptize:policies"
                  name = x.fully_qualified_name.gsub(/^baptize:policies:/, "")
                  policy = Capistrano::Baptize::DSL.policies[name.to_sym]
                  logger.info "#{name}:"
                  logger.info "->  servers:"
                  top.roles[name.to_sym].servers.each do |s|
                    logger.info "->    #{s}"
                  end
                  logger.info "->  dependencies:"
                  policy.dependencies.each do |d|
                    logger.info "->    #{d}"
                  end
                end
              end
            end
          end # end namespace policies

          namespace :ssh do
            desc "Describe available ssh connections"
            task :default do
              load_configuration
              count = 1
              roles.each do |name,servers|
                servers.each do |host|
                  puts "cap baptize:ssh:#{count} (#{name}) #{host}"
                  count = count + 1
                end
              end
            end

            1.upto(10).each do |num|
              task num.to_s.to_sym do
                load_configuration
                count = 1
                roles.each do |name,servers|
                  servers.each do |host|
                    if count == num
                      command = "ssh -i #{ssh_options[:keys]} #{user}@#{host}"
                      puts "ssh -i #{ssh_options[:keys]} #{user}@#{host}"
                      exec command
                    end
                    count = count + 1
                  end
                end
              end
            end
          end # end namespace ssh
        end # end namespace baptize
      end

    end
  end
end
