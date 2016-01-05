require 'rake'
require 'sshkit'
require 'capistrano/application'
require 'capistrano/dsl'
require 'capistrano/dsl/env'
require 'baptize/version'
require 'baptize/registry'
require 'baptize/package_definition'
require 'baptize/execution_scope'
require 'baptize/verification_failure'
require 'baptize/plugins/helpers'
require 'baptize/plugins/verifications'
require 'baptize/plugins/execution'
require 'baptize/plugins/apt'
require 'baptize/dsl'
require 'baptize/application'

Baptize::Registry.plugins << Capistrano::DSL::Env
Baptize::Registry.plugins << Baptize::Plugins::Helpers
Baptize::Registry.plugins << Baptize::Plugins::Verifications
Baptize::Registry.plugins << Baptize::Plugins::Execution
Baptize::Registry.plugins << Baptize::Plugins::Apt

extend Capistrano::DSL
extend Baptize::DSL

set_if_empty :logger, Proc.new { Baptize::Registry.logger }
set_if_empty :dry_run, true
set_if_empty :use_sudo, true
set_if_empty :use_bash, true
set_if_empty :ssh_verbose, !!ENV['VERBOSE']
