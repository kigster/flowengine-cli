# frozen_string_literal: true

require "tempfile"

RSpec.describe FlowEngine::CLI::FlowLoader do
  let(:sample_flow) { File.expand_path("../../fixtures/sample_flow.rb", __dir__) }
  let(:intro_flow) { File.expand_path("../../fixtures/intro_flow.rb", __dir__) }

  describe ".load" do
    context "with a valid flow file" do
      subject(:definition) { described_class.load(sample_flow) }

      it { is_expected.to be_a(FlowEngine::Definition) }
      its(:start_step_id) { is_expected.to eq(:greeting) }
    end

    context "with a flow that has introduction" do
      subject(:definition) { described_class.load(intro_flow) }

      it { is_expected.to be_a(FlowEngine::Definition) }
      its(:introduction) { is_expected.not_to be_nil }
      its(:start_step_id) { is_expected.to eq(:filing_status) }

      describe "introduction" do
        subject { definition.introduction }

        its(:label) { is_expected.to eq("Tell us about your tax situation") }
        its(:maxlength) { is_expected.to eq(500) }
        its(:placeholder) { is_expected.to include("married") }
      end
    end

    context "with a nonexistent file" do
      it "raises CLI::Error" do
        expect { described_class.load("/nonexistent.rb") }
          .to raise_error(FlowEngine::CLI::Error, /not found/)
      end
    end

    context "with a non-.rb file" do
      let(:tmpfile) { Tempfile.new(["flow", ".txt"]) }

      after { tmpfile.unlink }

      it "raises CLI::Error" do
        expect { described_class.load(tmpfile.path) }
          .to raise_error(FlowEngine::CLI::Error, /Not a .rb file/)
      end
    end
  end
end
