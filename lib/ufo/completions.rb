module Ufo
  class Completions < Command
    desc "script", "generates script that can be eval to setup auto-completion"
    long_desc Help.text("completions:script")
    def script
      Completer::Script.generate
    end
  end
end
