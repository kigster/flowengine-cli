# frozen_string_literal: true

require "dry/cli"
require_relative "commands/run"
require_relative "commands/graph"
require_relative "commands/validate_flow"
require_relative "commands/version"

module FlowEngine
  module CLI
    module Commands
      extend Dry::CLI::Registry

      register "run", Run
      register "graph", Graph
      register "validate", ValidateFlow
      register "version", Version
    end
  end
end
