# frozen_string_literal: true

RSpec.describe FlowEngine::CLI::Commands::Graph do
  subject(:command) { described_class.new }

  let(:sample_flow) { File.expand_path("../../../fixtures/sample_flow.rb", __dir__) }

  before do
    allow($stdout).to receive(:write)
    allow($stdout).to receive(:puts)
    allow($stderr).to receive(:write)
    allow($stderr).to receive(:puts)
  end

  describe "#call" do
    context "to stdout" do
      it "outputs mermaid diagram" do
        expect($stdout).to receive(:puts).with(/flowchart/).at_least(:once)
        allow($stdout).to receive(:puts).with(anything)
        command.call(flow_file: sample_flow)
      end
    end

    context "to file" do
      let(:tmpfile) { Tempfile.new(["diagram", ".mmd"]) }

      after { tmpfile.unlink }

      it "writes diagram to file" do
        command.call(flow_file: sample_flow, output: tmpfile.path)
        content = File.read(tmpfile.path)
        expect(content).to include("flowchart")
      end
    end

    context "with nonexistent file" do
      it "exits with error" do
        expect { command.call(flow_file: "/nonexistent.rb") }.to raise_error(SystemExit)
      end
    end
  end
end
