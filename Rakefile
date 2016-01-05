# -*- coding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'baptize/version'

begin
  require 'jeweler'
  #require 'rubygems'
  #gem :jeweler
  Jeweler::Tasks.new do |gemspec|
    gemspec.version = Baptize::VERSION
    gemspec.name = "baptize"
    gemspec.summary = "Baptize is an extension for Capistrano, that allows for server provisioning"
    gemspec.email = ["troels@knak-nielsen.dk"]
    gemspec.homepage = "http://github.com/troelskn/baptize"
    gemspec.description = gemspec.summary
    gemspec.authors = ["Troels Knak-Nielsen"]
    gemspec.license = 'MIT'
    # gemspec.add_dependency 'capistrano', '~> 3.4'
    gemspec.files = FileList['lib/**/*.rb'].to_a
    gemspec.executables = ['baptize']
  end
  Jeweler::GemcutterTasks.new
rescue LoadError => err
  puts "Jeweler not available. Install it with: sudo gem install jeweler"
  p err
end

desc "Generates API documentation"
task :rdoc do
  sh "rm -rf doc && rdoc lib"
end

task :default do
  puts "Run `rake release`. Update version number in `lib/baptize/version.rb`"
end
