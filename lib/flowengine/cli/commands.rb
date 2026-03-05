# frozen_string_literal: true

require "dry/cli"
require_relative "commands/run"
require_relative "commands/graph"
require_relative "commands/validate_flow"
require_relative "commands/version"
require_relative "ui_helper"

module FlowEngine
  module CLI
    module Commands
      extend Dry::CLI::Registry

      ::Dry::CLI::Command.include(UIHelper)

      register "run", Run
      register "graph", Graph
      register "validate", ValidateFlow
      register "version", Version
    end
  end
end
