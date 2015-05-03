require 'thor'

# Added 'required' option and stricter yes/no.
Thor::Shell::Basic.class_eval do
  alias :ask_original :ask
  def ask(statement, *args)
    options = args.last.is_a?(Hash) ? args.pop : {}
    color = args.first    
    statement << " [#{options[:required] ? 'required' : 'optional'}]\n>"
    begin
      response = ask_original(statement, color, options)
      if options[:required] && response == ''
        raise Thor::RequiredArgumentMissingError
      end
      response
    rescue Thor::RequiredArgumentMissingError
      say "Error: required", :red
      retry
    end
  end

  def no?(statement, color = nil)
    ask_bool('n', statement, color)
  end

  def yes?(statement, color = nil)
    ask_bool('y', statement, color)
  end

  private

  def ask_bool(y_or_n, statement, color)
    ask_original(statement, color, add_to_history: false, limited_to: %w[yes no y n])[0] == y_or_n
  end
end
