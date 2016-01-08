require 'shellwords'
require 'optparse'

module Baptize

  class << self
    attr_accessor :application
  end

  class Command
    attr_reader :name, :description, :block

    def initialize(name, description=nil, &block)
      @name, @description, @block = name.to_sym, description, block
    end

    def invoke(*args)
      block.call(*args)
    end

  end # class Command

  # Most of this is copy-paste fom Rake::Application
  # https://github.com/ruby/rake/blob/master/lib/rake/application.rb
  class Application

    attr_accessor :commands

    def initialize
      @original_dir = Dir.pwd
      @bapfiles = %w(bapfile Bapfile bapfile.rb Bapfile.rb)
      @commands = {}
      Baptize.application = self
      load 'baptize/commands.rb'
    end

    def run
      standard_exception_handling do
        parse_input
        load_bapfile
        dispatch
      end
    end

    def define_command(name, description=nil, &block)
      Command.new(name, description, &block).tap do |command|
        @commands[command.name] = command
      end
    end

    def parse_input
      @arguments = OptionParser.new do |opts|
        opts.banner = "baptize [OPTIONS] COMMAND"
        opts.separator ""
        opts.separator "COMMANDS are ..."

        width = [commands.values.map(&:name).map(&:length), 31].flatten.max
        commands.values.each do |command|
          opts.separator sprintf("    %-#{width}s  %s\n",
            command.name,
            command.description)
        end

        opts.separator ""
        opts.separator "OPTIONS are ..."

        opts.on_tail("-h", "--help", "-H", "Display this help message.") do
          puts opts
          exit
        end

        opts.on('--bapfile', '-f [FILENAME]', "Use FILENAME as the bapfile to search for.") do |value|
          value ||= ''
          @bapfiles.clear
          @bapfiles << value
        end

        opts.on('--verbose', '-v', "Log message to standard output.") do |value|
          Registry.execution_scope.set :verbose, true
        end

        opts.on('--version', '-V', "Display the program version.") do |value|
          puts "baptize, version #{Baptize::VERSION}"
          exit
        end

      end.parse(ARGV)
    end

    def dispatch
      args = @arguments.dup
      command_name = args.shift&.to_sym
      fail "No command given. Try baptize --help" if command_name.nil?
      command = commands[command_name]
      fail "Invalid command #{command_name}" unless command
      command.invoke(*args)
    end

    def load_bapfile
      standard_exception_handling do
        raw_load_bapfile
      end
    end

    def raw_load_bapfile # :nodoc:
      bapfile, location = find_bapfile_location
      fail "No Bapfile found (looking for: #{@bapfiles.join(', ')})" if bapfile.nil?
      @bapfile = bapfile
      Dir.chdir(location)
      print_bapfile_directory(location)
      load(File.expand_path(@bapfile)) if @bapfile && @bapfile != ''
    end

    def print_bapfile_directory(location) # :nodoc:
      $stderr.puts "(in #{Dir.pwd})" unless @original_dir == location
    end

    def find_bapfile_location # :nodoc:
      here = Dir.pwd
      until (fn = have_bapfile)
        Dir.chdir("..")
        return nil if Dir.pwd == here # || options.nosearch
        here = Dir.pwd
      end
      [fn, here]
    ensure
      Dir.chdir(@original_dir)
    end

    # True if one of the files in BAPFILES is in the current directory.
    # If a match is found, it is copied into @bapfile.
    def have_bapfile # :nodoc:
      @bapfiles.each do |fn|
        if File.exist?(fn)
          others = Dir.glob(fn, File::FNM_CASEFOLD).sort
          return others.size == 1 ? others.first : fn
        elsif fn == ''
          return fn
        end
      end
      return nil
    end

    def bapfile_location(backtrace=caller) # :nodoc:
      backtrace.map { |t| t[/([^:]+):/, 1] }

      re = /^#{@bapfile}$/
      re = /#{re.source}/i if windows?

      backtrace.find { |str| str =~ re } || ''
    end

    # Provide standard exception handling for the given block.
    def standard_exception_handling # :nodoc:
      yield
    rescue SystemExit
      # Exit silently with current status
      raise
    rescue OptionParser::InvalidOption => ex
      $stderr.puts ex.message
      exit(false)
    rescue Exception => ex
      # Exit with error message
      display_error_message(ex)
      exit_because_of_exception(ex)
    end

    # Display the error message that caused the exception.
    def display_error_message(ex) # :nodoc:
      $stderr.puts "Error during processing: #{$!}"
      $stderr.puts ex.backtrace.join("\n\t")
    end

    # Exit the program because of an unhandled exception.
    # (may be overridden by subclasses)
    def exit_because_of_exception(ex) # :nodoc:
      exit(false)
    end

  end
end
