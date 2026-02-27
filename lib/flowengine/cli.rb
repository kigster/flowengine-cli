# frozen_string_literal: true

require "flowengine"
require_relative "cli/version"
require_relative "cli/flow_loader"
require_relative "cli/renderer"
require_relative "cli/commands"

module FlowEngine
  module CLI
    class Error < StandardError; end
  end
end
