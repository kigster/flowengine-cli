# frozen_string_literal: true

require "tempfile"

RSpec.describe FlowEngine::CLI::Commands::Graph do
  let(:fixture_path) { File.expand_path("../../../fixtures/sample_flow.rb", __dir__) }

  describe "#call" do
    context "with stdout output" do
      it "prints Mermaid diagram to stdout" do
        expect { subject.call(flow_file: fixture_path) }.to output(/flowchart TD/).to_stdout
      end

      it "includes step nodes in the diagram" do
        expect { subject.call(flow_file: fixture_path) }.to output(/greeting/).to_stdout
      end

      it "includes transitions in the diagram" do
        expect { subject.call(flow_file: fixture_path) }.to output(/-->/).to_stdout
      end
    end

    context "with file output" do
      it "writes the diagram to the specified file" do
        tmpfile = Tempfile.new(["diagram", ".mmd"])
        tmpfile.close

        subject.call(flow_file: fixture_path, output: tmpfile.path)

        content = File.read(tmpfile.path)
        expect(content).to include("flowchart TD")
        expect(content).to include("greeting")
      ensure
        tmpfile&.unlink
      end

      it "prints a confirmation message to stderr" do
        tmpfile = Tempfile.new(["diagram", ".mmd"])
        tmpfile.close

        expect { subject.call(flow_file: fixture_path, output: tmpfile.path) }
          .to output(/Diagram written to/).to_stderr
      ensure
        tmpfile&.unlink
      end
    end

    context "with an invalid flow file" do
      it "exits with status 1" do
        expect do
          subject.call(flow_file: "/tmp/nonexistent_flow_#{Process.pid}.rb")
        end.to raise_error(SystemExit) { |e| expect(e.status).to eq(1) }
      end

      it "prints error message to stderr" do
        expect do
          subject.call(flow_file: "/tmp/nonexistent_flow_#{Process.pid}.rb")
        rescue SystemExit
          # expected
        end.to output(/Error:/).to_stderr
      end
    end
  end
end
