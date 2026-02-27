# frozen_string_literal: true

require "tempfile"
require "json"
require "tty-prompt"
require "tty-box"
require "tty-screen"

RSpec.describe FlowEngine::CLI::Commands::Run do
  let(:fixture_path) { File.expand_path("../../../fixtures/sample_flow.rb", __dir__) }

  describe "#call" do
    context "with a simple flow through the FileReturn path" do
      let(:prompt) { instance_double(TTY::Prompt) }
      let(:renderer) { FlowEngine::CLI::Renderer.new(prompt: prompt) }

      before do
        allow(FlowEngine::CLI::Renderer).to receive(:new).and_return(renderer)
        allow(TTY::Screen).to receive(:width).and_return(80)

        # Step 1: greeting -> FileReturn
        allow(prompt).to receive(:select)
          .with("What would you like to do?", %w[FileReturn GetEstimate LearnMore])
          .and_return("FileReturn")

        # Step 2: income_info -> W2 only (no Business, so goes to summary)
        allow(prompt).to receive(:multi_select)
          .with("Select your income types:", %w[W2 1099 Business Investment], min: 1)
          .and_return(%w[W2])

        # Step 3: summary -> display step
        allow(prompt).to receive(:keypress)
          .with("Press any key to continue...")
          .and_return(nil)
      end

      it "runs the flow to completion and outputs JSON" do
        output = capture_stdout { subject.call(flow_file: fixture_path) }

        expect(output).to include("Flow completed!")
        expect(output).to include('"greeting"')
      end

      it "writes results to output file when specified" do
        tmpfile = Tempfile.new(["result", ".json"])
        tmpfile.close

        capture_stdout { subject.call(flow_file: fixture_path, output: tmpfile.path) }

        result = JSON.parse(File.read(tmpfile.path))
        expect(result["answers"]).to have_key("greeting")
        expect(result["answers"]["greeting"]).to eq("FileReturn")
        expect(result["path_taken"]).to include("greeting", "income_info", "summary")
      ensure
        tmpfile&.unlink
      end
    end

    context "with a flow through Business details path" do
      let(:prompt) { instance_double(TTY::Prompt) }
      let(:renderer) { FlowEngine::CLI::Renderer.new(prompt: prompt) }

      before do
        allow(FlowEngine::CLI::Renderer).to receive(:new).and_return(renderer)
        allow(TTY::Screen).to receive(:width).and_return(80)

        # Step 1: greeting -> FileReturn
        allow(prompt).to receive(:select)
          .with("What would you like to do?", %w[FileReturn GetEstimate LearnMore])
          .and_return("FileReturn")

        # Step 2: income_info -> includes Business
        allow(prompt).to receive(:multi_select)
          .with("Select your income types:", %w[W2 1099 Business Investment], min: 1)
          .and_return(%w[W2 Business])

        # Step 3: business_details -> number_matrix
        allow(prompt).to receive(:ask).with("  LLC:", convert: :int, default: 0).and_return(2)
        allow(prompt).to receive(:ask).with("  SCorp:", convert: :int, default: 0).and_return(1)
        allow(prompt).to receive(:ask).with("  CCorp:", convert: :int, default: 0).and_return(0)

        # Step 4: summary -> display
        allow(prompt).to receive(:keypress)
          .with("Press any key to continue...")
          .and_return(nil)
      end

      it "navigates through business details and reaches summary" do
        output = capture_stdout { subject.call(flow_file: fixture_path) }

        expect(output).to include("Flow completed!")
      end
    end

    context "with an invalid flow file" do
      it "exits with status 1" do
        allow(TTY::Screen).to receive(:width).and_return(80)

        expect do
          subject.call(flow_file: "/tmp/nonexistent_flow_#{Process.pid}.rb")
        end.to raise_error(SystemExit) { |e| expect(e.status).to eq(1) }
      end
    end
  end

  private

  def capture_stdout(&block)
    original_stdout = $stdout
    $stdout = StringIO.new
    block.call
    $stdout.string
  ensure
    $stdout = original_stdout
  end
end
