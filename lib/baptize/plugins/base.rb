module Capistrano
  module Baptize
    module Plugins
      module Base
        def fail_verification(message = "Assertion failed")
          raise VerificationFailure, message
        end

        def has_file(path)
          remote_assert("test -e #{path.shellescape}") or fail_verification("Remote file #{path} does not exist")
        end

        def has_directory(path)
          remote_assert("test -d #{path.shellescape}") or fail_verification("Remote directory #{path} does not exist")
        end

        def matches_local(local_path, remote_path)
          raise VerificationFailure, "Couldn't find local file #{local_path}" unless ::File.exists?(local_path)
          require 'digest/md5'
          local_md5 = Digest::MD5.hexdigest(::File.read(local_path))
          md5_of_file(remote_path, local_md5) or fail_verification("Remote file #{remote_path} doesn't match local file #{local_path}")
        end

        def file_contains(path, text, options = {})
          options = {:mode => :text}.merge(options)
          if options[:mode] == :text
            command = Array(text.strip.split("\n")).flatten.map {|line| "grep --fixed-strings #{line.shellescape} #{path.shellescape}" }.join(" && ")
          elsif options[:mode] == :perl
            command = "grep --perl-regexp #{text.shellescape} #{path.shellescape}"
          else
            command = "grep --basic-regexp #{text.shellescape} #{path.shellescape}"
          end
          remote_assert command
        end

        def has_executable(path)
          remote_assert("which #{path.shellescape}") or fail_verification("No executable #{path} found")
        end

        def has_user(name)
          remote_assert("id -u #{name.to_s.shellescape}") or fail_verification("No user #{name}")
        end
      end
    end
  end
end
