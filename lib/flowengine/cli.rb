# frozen_string_literal: true

require "flowengine"
require_relative "cli/version"
require_relative "cli/flow_loader"
require_relative "cli/renderer"
require_relative "cli/commands"

module FlowEngine
  # Terminal UI adapter for flowengine: runs flows interactively via Dry::CLI
  # and TTY components, and supports graph export and flow validation.
  module CLI
    # Raised when flowengine-cli encounters a load, validation, or runtime error.
    class Error < StandardError; end
  end
end
