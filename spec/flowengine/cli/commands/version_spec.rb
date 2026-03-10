# frozen_string_literal: true

RSpec.describe FlowEngine::CLI::Commands::Version do
  subject(:command) { described_class.new }

  before do
    allow($stdout).to receive(:write)
    allow($stdout).to receive(:puts)
  end

  describe "#call" do
    it "prints CLI version" do
      expect($stdout).to receive(:puts).with(/flowengine-cli #{Regexp.escape(FlowEngine::CLI::VERSION)}/)
      allow($stdout).to receive(:puts).with(anything)
      command.call
    end

    it "prints engine version" do
      expect($stdout).to receive(:puts).with(/flowengine #{Regexp.escape(FlowEngine::VERSION)}/)
      allow($stdout).to receive(:puts).with(anything)
      command.call
    end
  end
end
