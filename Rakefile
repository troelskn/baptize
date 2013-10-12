# -*- coding: utf-8 -*-
begin
  require 'jeweler'
  #require 'rubygems'
  #gem :jeweler
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "baptize"
    gemspec.summary = "Baptize is an extension for Capistrano, that allows for server provisioning"
    gemspec.email = ["troels@knak-nielsen.dk"]
    gemspec.homepage = "http://github.com/troelskn/baptize"
    gemspec.description = gemspec.summary
    gemspec.authors = ["Troels Knak-Nielsen"]
    gemspec.license = 'MIT'
    gemspec.add_dependency 'capistrano', '~> 2.15.5'
    gemspec.files = FileList['lib/**/*.rb'].to_a
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
  puts "Run `rake version:bump:patch release`"
end

