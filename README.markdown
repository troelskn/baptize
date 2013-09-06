Baptize
---

Entirely undocumented for the time being.

To install, run:

    rake install

A sample `Capfile` to get you started:

    require 'bundler'
    require 'capistrano'
    require 'baptize'
    set :capistrano_path, "#{root_path}/capistrano"
    set :assets_path, "#{capistrano_path}/assets"
    load_configuration :roles

    Dir.glob("#{capistrano_path}/packages/**/*.rb").each do |package|
      load(package)
    end

    Dir.glob("#{capistrano_path}/recipes/**/*.rb").each do |recipe|
      load(recipe)
    end

