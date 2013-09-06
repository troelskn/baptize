module Capistrano
  module Baptize

    # Defines all baptize top-level tasks
    def self.install(scope)
      scope.instance_eval do
        set :root_path, File.expand_path(Dir.pwd)
        set :capistrano_path, "#{root_path}/capistrano"
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

          desc "Configures all available roles"
          task :install do ; end

          desc "List configured roles"
          task :roles do
            load_configuration
            result = []
            logger.info "Configured roles:"
            top.roles.each do |name,r|
              logger.info "#{name} [" + r.servers.join(", ") + "]"
            end
          end

          namespace :policies do
            desc "List configured policies"
            task :default do
              load_configuration
              logger.info "Configured policies:"
              tasks.flatten.each do |x|
                if x.kind_of?(Capistrano::TaskDefinition) && x.fully_qualified_name != "baptize:policies"
                  name = x.fully_qualified_name.gsub(/^baptize:policies:/, "")
                  policy = Capistrano::Baptize::DSL.policies[name.to_sym]
                  logger.info "#{name} [" + policy.dependencies.join(", ") + "]"
                end
              end
              # logger.info "Policies have been defined for roles: " + policies.join(", ")
            end
          end

        end
      end
    end

  end
end
