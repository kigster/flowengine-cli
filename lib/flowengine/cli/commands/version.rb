# frozen_string_literal: true

module FlowEngine
  module CLI
    module Commands
      class Version < Dry::CLI::Command
        desc "Print version information"

        def call(**)
          puts "flowengine-cli #{FlowEngine::CLI::VERSION}"
          puts "flowengine #{FlowEngine::VERSION}"
        end
      end
    end
  end
end
