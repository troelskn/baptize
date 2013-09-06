Baptize
===

Baptize is an extension for Capistrano, that allows for server provisioning. The API resembles [Sprinkle](https://github.com/sprinkle-tool/sprinkle), but the underlying implementation is quite different. Where Sprinkle tries to compile a static payload of commands and push to the server, Baptize is executed in runtime. It also reuses much more of Capistrano, than Sprinkle does. Basically, each Baptize package is a capistrano task - Baptize just adds some helpers and fancy dsl on top, to make it look declarative.

Be warned that Baptize is less than a week old at the time of this writing, and it has no test coverage - so it's probably riddled with bugs. That said, I do eat my own dog food, so it's at least somewhat functional.

Setup
---

At some point, I'll probably wrap this procedure in a generator, but for now you'll have to do so manually.

To get started, create a `Gemfile`:

```ruby
source 'https://rubygems.org'
gem 'capistrano', '~> 2.15'
gem 'baptize'
```

And a `Capfile`:

```ruby
require 'bundler'
require 'capistrano'
require 'baptize'
load_configuration :roles
Dir.glob("#{capistrano_path}/packages/**/*.rb").each do |package|
  load(package)
end
Dir.glob("#{capistrano_path}/recipes/**/*.rb").each do |recipe|
  load(recipe)
end
```

And a couple of folders and files:

    ./capistrano/
    ./capistrano/config/
    ./capistrano/config/roles.rb               # Globally applied configuration. Define roles here.
    ./capistrano/config/baptize.rb             # Contains config files used by baptize packages. Define policies here.
    ./capistrano/packages/                     # Put package definitions in here.
    ./capistrano/recipes/                      # Put regular capistrano tasks in here.
    ./capistrano/assets/                       # Place auxiliary files here.

And Finally, run the following command:

    bundle

Sample configuration
---

First define some roles, by opening up `config/roles.rb` - This is just regular Capistrano stuff. For example:

```ruby
role :server, "192.168.1.1"
```

Next define a policy for the server. Open up `config/baptize.rb` and put this:

```ruby
policy :server do
  requires :system_update
end
```

This defines that the role `:server` needs a package `system_update`.

You probably should define which login credentials to use as well:

```ruby
# ssh login user
set :user, 'ubuntu'
# ssh key location
ssh_options[:keys] = '~/.ssh/aws-key.pem'
# run commands through sudo
set :use_sudo, true
```

Note that since this is defined inside `config/baptize.rb`, it won't apply to capistrano recipes outside of baptize. The roles, on the other hand, is globally loaded (That happens in the `Capfile`).

Better create that packages then. Open up `packages/system_update.rb`:

```ruby
package :system_update do
  description "System Update"
  install do
    run 'apt-get update -y'
    run 'apt-get upgrade -y'
  end
end
```

This defines a package, that will upgrade the apt package manager of the target system.

Deploying policies
---

You can now run the following command:

    cap baptize

Which should make capistrano ssh in to the `:server` role and try to update apt. It'll probably fail, unless you actually have a server running at that IP.

If you want to just configure a single role, you can do so by running:

    cap baptize:policies:server

Using Baptize alongside Capistrano
---

If you also want to use Capistrano for regular application deployment (what it's actually ment for), you might want to create a file in `config/deploy.rb` to hold settings for this. E.g.:

```ruby
set :application, "set your application name here"
set :repository,  "set your repository location here"
```

And to make sure it is loaded, modify your `Capfile` to include:

```ruby
load 'deploy'
load 'deploy/assets' # For using Rails' asset pipeline
before 'deploy' do
  load_configuration :deploy
end
```

---

TODO: There is more to Baptize, but that'll have to wait for now.
