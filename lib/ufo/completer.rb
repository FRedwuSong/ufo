# Code Explanation.  This is mainly focused on the run method.
#
# There are 3 main branches of logic for completions:
#
#   1. top-level commands - when there are zero completed words
#   2. params completions - when a command has some required params
#   3. options completions - when we have finished auto-completing the top-level command and required params, the rest of the completion words will be options
#
# Terms:
#
#   params - these are params in the command itself. Example: for the method `scale(service, count)` the params would be `service, count`.
#   options - these are cli options flags.  Examples: --noop, --verbose
#
# When we are done processing method params, the completions will be only options. When the detected params size is greater than the arity we are have finished auto-completing the parameters in the method declaration.  For example, say you had a method for a CLI command with the following form:
#
#   scale(service, count) = arity of 2
#
#   ufo scale service count [TAB] # there are 3 params including the "scale" command
#
# So the completions will be something like:
#
#   --noop --verbose etc
#
# A note about artity values:
#
# We are using the arity of the command method to determine if we have finish auto-completing the params completions. When the ruby method has a splat param, it's arity will be negative.  Here are some example methods and their arities.
#
#    ship(service) = 1
#    scale(service, count) = 2
#    ships(*services) = -1
#    foo(example, *rest) = -2
#
# Fortunately, negative and positive arity values are processed the same way. So we take simply take the abs of the arity.
#
# To test:
#
#   ufo completions
#   ufo completions hello
#   ufo completions hello name
#   ufo completions hello name --
#   ufo completions hello name --noop
#
#   ufo completions
#   ufo completions sub:goodbye
#   ufo completions sub:goodbye name
#
# Note when testing, the first top-level word must be an exact match
#
#   ufo completions hello # works fine
#   ufo completions he # incomplete, this will just break
#
# The completions assumes that the top-level word that is being passed in
# from completor/scripts.sh will always match exactly.  This must be the
# case.  For parameters, the word does not have to match exactly.
#
module Ufo
  class Completer
    autoload :Script, 'ufo/completer/script'

    def initialize(*params)
      @params = params
    end

    def current_command
      @params[0]
    end

    # Example: sub:goodbye => "sub"
    def namespace
      return nil unless current_command

      if current_command.include?(':')
        words = current_command.split(':')
        words.pop
        words.join(':')
      end
    end

    # Example: sub:goodbye => "goodbye"
    def trailing_command
      current_command.split(':').last
    end

    def run
      if @params.size == 0
        puts all_commands
        return
      end

      # will only get to here if the top-level command has been fully auto-completed.
      arity = command_class.instance_method(trailing_command).arity.abs
      if @params.size <= arity
        puts params_completions(current_command)
      else
        puts options_completions(current_command)
      end
    end

    # all top-level commands
    def all_commands
      # Interesing, extra :help commands show up here but no whne using
      # Ufo::Command.help_list in main_help -> thor_list
      # We'll filter out :help for auto-completion.
      commands = Ufo::Command.namespaced_commands
      commands.reject { |c| c =~ /:help$/ }
    end

    def params_completions(current_command)
      method_params = command_class.instance_method(trailing_command).parameters
      # Example:
      # >> Sub.instance_method(:goodbye).parameters
      # => [[:req, :name]]
      # >>
      method_params.map!(&:last)

      offset = @params.size - 1
      offset_params = method_params[offset..-1]
      method_params[offset..-1].first
    end

    def options_completions(current_command)
      used = ARGV.select { |a| a.include?('--') } # so we can remove used options

      method_options = command_class.all_commands[trailing_command].options.keys
      class_options = command_class.class_options.keys

      all_options = method_options + class_options

      all_options.map! { |o| "--#{o.to_s.dasherize}" }
      filtered_options = all_options - used
      filtered_options
    end

    def command_class
      @command_class ||= Ufo::Command.klass_from_namespace(namespace)
    end
  end
end
