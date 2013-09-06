require 'baptize/dsl'
require 'baptize/install'
require 'baptize/helpers'
Dir.glob(File.join(File.dirname(__FILE__), "baptize/plugins/**/*.rb")).each do |f|
  require f
end

Capistrano::Configuration.instance(:must_exist).load do
  class << self
    include Capistrano::Baptize::DSL
    include Capistrano::Baptize::Helpers
    Capistrano::Baptize::Plugins.constants.collect do |const_name|
      Capistrano::Baptize::Plugins.const_get(const_name)
    end.select do |const|
      const.class == Module
    end.each do |m|
      include m
    end
  end
  Capistrano::Baptize.install(self)
end
