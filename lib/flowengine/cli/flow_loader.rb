# frozen_string_literal: true

module FlowEngine
  module CLI
    class FlowLoader
      def self.load(path)
        new(path).load
      end

      def initialize(path)
        @path = File.expand_path(path)
        validate_path!
      end

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

      def validate_path!
        raise FlowEngine::CLI::Error, "File not found: #{@path}" unless File.exist?(@path)
        raise FlowEngine::CLI::Error, "Not a .rb file: #{@path}" unless @path.end_with?(".rb")
      end
    end
  end
end
