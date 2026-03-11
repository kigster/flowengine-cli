# frozen_string_literal: true

RSpec.describe FlowEngine::CLI::Commands::ValidateFlow do
  subject(:command) { described_class.new }

  let(:sample_flow) { File.expand_path("../../../fixtures/sample_flow.rb", __dir__) }
  let(:intro_flow) { File.expand_path("../../../fixtures/intro_flow.rb", __dir__) }

  before do
    allow($stdout).to receive(:write)
    allow($stdout).to receive(:puts)
    allow($stderr).to receive(:write)
    allow($stderr).to receive(:puts)
  end

  describe "#call" do
    context "with a valid flow without introduction" do
      it "completes without error" do
        expect { command.call(flow_file: sample_flow) }.not_to raise_error
      end
    end

    context "with a valid flow with introduction" do
      it "completes without error and reports introduction" do
        expect($stdout).to receive(:puts).with(/Introduction: yes/).at_least(:once)
        allow($stdout).to receive(:puts).with(anything)
        command.call(flow_file: intro_flow)
      end
    end

    context "with a nonexistent file" do
      it "exits with error" do
        expect { command.call(flow_file: "/nonexistent.rb") }.to raise_error(SystemExit)
      end
    end
  end

  describe "#print_introduction_info" do
    context "with maxlength" do
      let(:intro) { FlowEngine::Introduction.new(label: "Test", maxlength: 2000) }

      it "prints maxlength detail" do
        expect($stdout).to receive(:puts).with("  Introduction: yes (maxlength: 2000)")
        command.send(:print_introduction_info, intro)
      end
    end

    context "without maxlength" do
      let(:intro) { FlowEngine::Introduction.new(label: "Test", maxlength: nil) }

      it "prints no length limit" do
        expect($stdout).to receive(:puts).with("  Introduction: yes (no length limit)")
        command.send(:print_introduction_info, intro)
      end
    end
  end
end
