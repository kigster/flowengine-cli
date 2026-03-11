# frozen_string_literal: true

require "tempfile"

RSpec.describe FlowEngine::CLI::Commands::Run do
  subject(:command) { described_class.new }

  let(:flow_file) { File.expand_path("../../../fixtures/sample_flow.rb", __dir__) }
  let(:intro_flow_file) { File.expand_path("../../../fixtures/intro_flow.rb", __dir__) }

  before do
    allow($stdout).to receive(:write)
    allow($stdout).to receive(:puts)
    allow($stderr).to receive(:write)
    allow($stderr).to receive(:puts)
  end

  describe "#call" do
    context "with a simple flow (no introduction)" do
      let(:mock_prompt) { instance_double(TTY::Prompt) }

      before do
        allow(TTY::Prompt).to receive(:new).and_return(mock_prompt)
        # sample_flow: greeting (single_select) -> info (display)
        allow(mock_prompt).to receive(:select).and_return("LearnMore")
        allow(mock_prompt).to receive(:keypress)
      end

      it "completes the flow and outputs JSON" do
        expect { command.call(flow_file: flow_file) }.not_to raise_error
      end
    end

    context "with output file option" do
      let(:mock_prompt) { instance_double(TTY::Prompt) }
      let(:tmpfile) { Tempfile.new(["flow_result", ".json"]) }

      before do
        allow(TTY::Prompt).to receive(:new).and_return(mock_prompt)
        allow(mock_prompt).to receive(:select).and_return("LearnMore")
        allow(mock_prompt).to receive(:keypress)
      end

      after { tmpfile.unlink }

      it "writes JSON to the specified file" do
        command.call(flow_file: flow_file, output: tmpfile.path)
        result = JSON.parse(File.read(tmpfile.path))
        expect(result).to include("flow_file", "path_taken", "answers")
      end
    end

    context "with a flow that has introduction and skip_introduction" do
      let(:mock_prompt) { instance_double(TTY::Prompt) }

      before do
        allow(TTY::Prompt).to receive(:new).and_return(mock_prompt)
        # Flow steps: filing_status -> dependents -> done
        allow(mock_prompt).to receive(:select).and_return("single")
        allow(mock_prompt).to receive(:ask).with("How many dependents do you have?",
          convert: :int).and_return(0)
        allow(mock_prompt).to receive(:keypress)
      end

      it "skips introduction and runs all steps" do
        expect { command.call(flow_file: intro_flow_file, skip_introduction: true) }
          .not_to raise_error
      end
    end

    context "when flow file does not exist" do
      it "exits with error" do
        expect { command.call(flow_file: "/nonexistent/flow.rb") }.to raise_error(SystemExit)
      end
    end
  end

  describe "#build_result (via call)" do
    let(:mock_prompt) { instance_double(TTY::Prompt) }
    let(:tmpfile) { Tempfile.new(["flow_result", ".json"]) }

    before do
      allow(TTY::Prompt).to receive(:new).and_return(mock_prompt)
      allow(mock_prompt).to receive(:select).and_return("LearnMore")
      allow(mock_prompt).to receive(:keypress)
    end

    after { tmpfile.unlink }

    it "includes all required fields in the JSON output" do
      command.call(flow_file: flow_file, output: tmpfile.path)
      result = JSON.parse(File.read(tmpfile.path))

      expect(result).to include(
        "flow_file" => flow_file,
        "steps_completed" => be_a(Integer),
        "completed_at" => match(/\d{4}-\d{2}-\d{2}/)
      )
      expect(result["path_taken"]).to be_an(Array)
      expect(result["answers"]).to be_a(Hash)
    end

    it "does not include introduction_text when there is none" do
      command.call(flow_file: flow_file, output: tmpfile.path)
      result = JSON.parse(File.read(tmpfile.path))
      expect(result).not_to have_key("introduction_text")
    end
  end

  describe "#build_llm_client" do
    it "returns nil when no API key is available" do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("ANTHROPIC_API_KEY", nil).and_return(nil)
      allow(ENV).to receive(:fetch).with("OPENAI_API_KEY", nil).and_return(nil)
      allow(ENV).to receive(:fetch).with("GEMINI_API_KEY", nil).and_return(nil)
      expect(command.send(:build_llm_client)).to be_nil
    end

    it "returns a client when an API key is available" do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("ANTHROPIC_API_KEY", nil).and_return("sk-ant-test")
      allow(ENV).to receive(:fetch).with("OPENAI_API_KEY", nil).and_return(nil)
      allow(ENV).to receive(:fetch).with("GEMINI_API_KEY", nil).and_return(nil)
      client = command.send(:build_llm_client)
      expect(client).to be_a(FlowEngine::LLM::Client)
    end
  end

  describe "#show_introduction?" do
    let(:definition_with_intro) do
      FlowEngine::CLI::FlowLoader.load(intro_flow_file)
    end
    let(:definition_without_intro) do
      FlowEngine::CLI::FlowLoader.load(flow_file)
    end

    it "returns true when introduction exists and not skipped" do
      result = command.send(:show_introduction?, definition_with_intro, {})
      expect(result).to be_truthy
    end

    it "returns false when skip_introduction is true" do
      result = command.send(:show_introduction?, definition_with_intro, { skip_introduction: true })
      expect(result).to be_falsey
    end

    it "returns false when no introduction defined" do
      result = command.send(:show_introduction?, definition_without_intro, {})
      expect(result).to be_falsey
    end
  end

  describe "#submit_with_llm" do
    let(:engine) { FlowEngine::Engine.new(FlowEngine::CLI::FlowLoader.load(intro_flow_file)) }
    let(:llm_client) { instance_double(FlowEngine::LLM::Client) }

    context "when LLM succeeds" do
      before do
        allow(llm_client).to receive(:parse_introduction).and_return(
          { filing_status: "single", dependents: 0 }
        )
      end

      it "pre-fills answers" do
        command.send(:submit_with_llm, engine, "I am single with no dependents", llm_client)
        expect(engine.answers).to include(filing_status: "single", dependents: 0)
      end
    end

    context "when sensitive data is detected" do
      before do
        allow(llm_client).to receive(:parse_introduction).and_raise(
          FlowEngine::Errors::SensitiveDataError, "SSN detected"
        )
      end

      it "does not raise, prints warning instead" do
        expect do
          command.send(:submit_with_llm, engine, "My SSN is 123-45-6789", llm_client)
        end.not_to raise_error
      end
    end

    context "when LLM fails" do
      before do
        allow(llm_client).to receive(:parse_introduction).and_raise(
          FlowEngine::Errors::LLMError, "API unavailable"
        )
      end

      it "does not raise, prints warning instead" do
        expect do
          command.send(:submit_with_llm, engine, "some text", llm_client)
        end.not_to raise_error
      end
    end
  end
end
