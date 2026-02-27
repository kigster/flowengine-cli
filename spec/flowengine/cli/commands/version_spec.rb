# frozen_string_literal: true

RSpec.describe FlowEngine::CLI::Commands::Version do
  describe "#call" do
    it "prints flowengine-cli version" do
      expect { subject.call }.to output(/flowengine-cli #{Regexp.escape(FlowEngine::CLI::VERSION)}/).to_stdout
    end

    it "prints flowengine core version" do
      expect { subject.call }.to output(/flowengine #{Regexp.escape(FlowEngine::VERSION)}/).to_stdout
    end

    it "prints both version lines" do
      expected = "flowengine-cli #{FlowEngine::CLI::VERSION}\nflowengine #{FlowEngine::VERSION}\n"
      expect { subject.call }.to output(expected).to_stdout
    end
  end
end
