# frozen_string_literal: true

RSpec.describe FlowEngine::CLI::FlowLoader do
  let(:fixture_path) { File.expand_path("../../fixtures/sample_flow.rb", __dir__) }

  describe ".load" do
    context "with a valid flow file" do
      it "returns a FlowEngine::Definition" do
        definition = described_class.load(fixture_path)

        expect(definition).to be_a(FlowEngine::Definition)
      end

      it "loads the correct start step" do
        definition = described_class.load(fixture_path)

        expect(definition.start_step_id).to eq(:greeting)
      end

      it "loads all steps" do
        definition = described_class.load(fixture_path)

        expect(definition.step_ids).to contain_exactly(
          :greeting, :income_info, :business_details, :estimate, :info, :summary
        )
      end
    end

    context "with a non-existent file" do
      it "raises a FlowEngine::CLI::Error" do
        expect do
          described_class.load("/tmp/nonexistent_flow_#{Process.pid}.rb")
        end.to raise_error(FlowEngine::CLI::Error, /File not found/)
      end
    end

    context "with a non-.rb file" do
      it "raises a FlowEngine::CLI::Error" do
        tmpfile = Tempfile.new(["flow", ".txt"])
        tmpfile.write("some content")
        tmpfile.close

        expect do
          described_class.load(tmpfile.path)
        end.to raise_error(FlowEngine::CLI::Error, /Not a \.rb file/)
      ensure
        tmpfile&.unlink
      end
    end

    context "with a file containing a syntax error" do
      it "raises a FlowEngine::CLI::Error" do
        tmpfile = Tempfile.new(["flow", ".rb"])
        tmpfile.write("def foo(")
        tmpfile.close

        expect do
          described_class.load(tmpfile.path)
        end.to raise_error(FlowEngine::CLI::Error, /Syntax error/)
      ensure
        tmpfile&.unlink
      end
    end
  end

  describe "#initialize" do
    it "expands the path" do
      loader = described_class.new(fixture_path)

      expect(loader.instance_variable_get(:@path)).to eq(File.expand_path(fixture_path))
    end
  end
end
