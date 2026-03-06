# frozen_string_literal: true

module FlowEngine
  module CLI
    # Loads a flow definition from a Ruby file by evaluating it in a top-level
    # binding. Expects the file to define a flow via FlowEngine.define and
    # return a FlowEngine::Definition.
    class FlowLoader
      # Load a flow definition from a file.
      # @param path [String] path to a .rb flow definition file
      # @return [FlowEngine::Definition] the evaluated definition
      # @raise [FlowEngine::CLI::Error] if file is missing, not .rb, or has syntax errors
      def self.load(path)
        new(path).load
      end

      # @param path [String] path to the flow definition file (will be expanded)
      def initialize(path)
        @path = File.expand_path(path)
        validate_path!
      end

      # Evaluates the file and returns the resulting definition.
      # @return [FlowEngine::Definition]
      # @raise [FlowEngine::CLI::Error] on syntax error
      def load
        content = File.read(@path)
        # Evaluate in a clean binding that has FlowEngine available
        # rubocop:disable Security/Eval
        eval(content, TOPLEVEL_BINDING.dup, @path, 1)
        # rubocop:enable Security/Eval
      rescue SyntaxError => e
        raise FlowEngine::CLI::Error, "Syntax error in #{@path}: #{e.message}"
      end

      private

      # @raise [FlowEngine::CLI::Error] if path does not exist or does not end with .rb
      def validate_path!
        raise FlowEngine::CLI::Error, "File not found: #{@path}" unless File.exist?(@path)
        raise FlowEngine::CLI::Error, "Not a .rb file: #{@path}" unless @path.end_with?(".rb")
      end
    end
  end
end
