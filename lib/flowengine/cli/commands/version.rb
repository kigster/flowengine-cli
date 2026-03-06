# frozen_string_literal: true

module FlowEngine
  module CLI
    module Commands
      # Prints flowengine-cli and flowengine gem versions to stdout.
      class Version < Dry::CLI::Command
        desc "Print version information"

        # @param **_ [Hash] ignored options
        # @return [void]
        def call(**)
          puts "flowengine-cli #{FlowEngine::CLI::VERSION}"
          puts "flowengine #{FlowEngine::VERSION}"
        end
      end
    end
  end
end
