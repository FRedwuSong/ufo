require "thor"
require "active_support" # for autoload
require "active_support/core_ext"

module Ufo
  class CLI
    def self.start(given_args=ARGV)
      new(given_args).start
    end

    def self.thor_tasks
      Ufo::Command.namespaced_commands
    end

    def initialize(given_args=ARGV, **config)
      @given_args = given_args.dup
      @config = config
    end

    def start
      setup_auto_load
      command_class = lookup(full_command)
      if command_class
        command_class.perform(full_command, thor_args)
      else
        main_help
      end
    end

    def setup_auto_load
      autoload_paths = [File.expand_path("../../", __FILE__)]
      ActiveSupport::Dependencies.autoload_paths += autoload_paths
    end

    # thor_args normalized the args Array to work with our Thor command
    # subclasses.
    # 1. The namespace is stripped
    # 2. The help is shifted in front if a help flag is detected
    def thor_args
      args = @given_args.clone

      # Allow calling for help via:
      #   cli-template command help
      #   cli-template command -h
      #   cli-template command --help
      #   cli-template command -D
      #
      # as well thor's normal way:
      #
      #   cli-template help command
      help_args = args & help_flags
      if help_args.empty?
        args[0] = meth # reassigns the command without the namespace
      else
        # Allow using help flags at the end of the command to trigger help menu
        args -= help_flags # remove "help" and help flags from args
        args[0] = meth # first command will always be the meth now since
          # we removed the help flags
        args.unshift("help")
      end
      args.compact
    end

    def full_command
      # Removes any args that starts with -, those are option args.
      # Also remove "help" flag.
      args = @given_args.reject {|o| o =~ /^-/ } - help_flags
      command = args[0] # first argument should always be the command
      Ufo::Command.autocomplete(command)
    end

    # 1. look up Thor tasks
    # 2. look up Rake tasks - currently disabled
    # 3. help menu with all commands when both Thor and Rake tasks are not found
    #
    # Example:
    #
    #   lookup("sub:hello") => Sub
    def lookup(full_command)
      thor_task_found = Ufo::Command.namespaced_commands.include?(full_command)
      if thor_task_found
        return Ufo::Command.klass_from_namespace(namespace)
      end

      rake_task_found = Ufo::RakeCommand.namespaced_commands.include?(full_command)
      if rake_task_found
        return Ufo::RakeCommand
      end
    end

    def version_flags
      ["--version", "-v"]
    end

    # ["-h", "-?", "--help", "-D", "help"]
    def help_flags
      Thor::HELP_MAPPINGS + ["help"]
    end

    def namespace
      return nil unless full_command

      if full_command.include?(':')
        words = full_command.split(':')
        words.pop
        words.join(':')
      end
    end

    def meth
      return nil unless full_command

      if full_command.include?(':')
        full_command.split(':').pop
      else
        full_command
      end
    end

    # Allow calling version via:
    #   ufo version
    #   ufo --version
    #   ufo -v
    def version_flag?
      args = @given_args
      args.length == 1 && !(args & version_flags).empty?
    end

    def main_help
      if version_flag?
        Ufo::Main.perform("version", ["version"])
        return
      end

      shell = Thor::Shell::Basic.new
      shell.say "Commands:"
      shell.print_table(thor_list, :indent => 2, :truncate => true)

      # TODO: commenting out for now, feels weird to show the rake tasks
      # automatically also by default. Maybe add an option for this.
      # unless rake_list.empty?
      #   shell.say "\nCommands via rake:"
      #   shell.print_table(rake_list, :indent => 2, :truncate => true)
      # end

      shell.say "\n"
      shell.say Help.text(:main) + "\n"
    end

    def thor_list
      Ufo::Command.help_list(show_all_tasks)
    end

    def rake_list
      list = Ufo::RakeCommand.formatted_rake_tasks(show_all_tasks)
      list.map do |array|
        array[0] = "ufo #{array[0]}"
        array
      end
    end

    def show_all_tasks
      @given_args.include?("--all") || @given_args.include?("-A")
    end
  end
end
