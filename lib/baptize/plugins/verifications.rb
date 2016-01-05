module Baptize
  module Plugins

    module Verifications
      def fail_verification(message = "Verification failed")
        raise VerificationFailure.new(message)
      end

      def has_file(path)
        remote_assert("test -e #{path.shellescape}") or fail_verification("Remote file #{path} does not exist")
      end

      def has_directory(path)
        remote_assert("test -d #{path.shellescape}") or fail_verification("Remote directory #{path} does not exist")
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
