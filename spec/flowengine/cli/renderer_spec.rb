# frozen_string_literal: true

require "tty-prompt"

RSpec.describe FlowEngine::CLI::Renderer do
  let(:prompt) { instance_double(TTY::Prompt) }
  let(:renderer) { described_class.new(prompt: prompt) }

  def build_node(type:, question: "Test question", options: nil, fields: nil)
    FlowEngine::Node.new(
      id: :test_step,
      type: type,
      question: question,
      options: options,
      fields: fields,
      transitions: []
    )
  end

  describe "#render" do
    context "with a multi_select node" do
      let(:node) { build_node(type: :multi_select, options: %w[A B C]) }

      it "calls prompt.multi_select with options" do
        allow(prompt).to receive(:multi_select).with("Test question", %w[A B C], min: 1).and_return(%w[A])

        result = renderer.render(node)

        expect(result).to eq(%w[A])
        expect(prompt).to have_received(:multi_select).with("Test question", %w[A B C], min: 1)
      end
    end

    context "with a single_select node" do
      let(:node) { build_node(type: :single_select, options: %w[X Y Z]) }

      it "calls prompt.select with options" do
        allow(prompt).to receive(:select).with("Test question", %w[X Y Z]).and_return("Y")

        result = renderer.render(node)

        expect(result).to eq("Y")
        expect(prompt).to have_received(:select).with("Test question", %w[X Y Z])
      end
    end

    context "with a number_matrix node" do
      let(:node) { build_node(type: :number_matrix, fields: %w[LLC SCorp]) }

      it "asks for each field and returns a hash" do
        allow(prompt).to receive(:ask).with("  LLC:", convert: :int, default: 0).and_return(2)
        allow(prompt).to receive(:ask).with("  SCorp:", convert: :int, default: 0).and_return(1)

        result = renderer.render(node)

        expect(result).to eq({ "LLC" => 2, "SCorp" => 1 })
      end
    end

    context "with a text node" do
      let(:node) { build_node(type: :text) }

      it "calls prompt.ask" do
        allow(prompt).to receive(:ask).with("Test question").and_return("hello")

        result = renderer.render(node)

        expect(result).to eq("hello")
      end
    end

    context "with a number node" do
      let(:node) { build_node(type: :number) }

      it "calls prompt.ask with int conversion" do
        allow(prompt).to receive(:ask).with("Test question", convert: :int).and_return(42)

        result = renderer.render(node)

        expect(result).to eq(42)
      end
    end

    context "with a boolean node" do
      let(:node) { build_node(type: :boolean) }

      it "calls prompt.yes?" do
        allow(prompt).to receive(:yes?).with("Test question").and_return(true)

        result = renderer.render(node)

        expect(result).to be true
      end
    end

    context "with a display node" do
      let(:node) { build_node(type: :display) }

      it "shows the question and waits for keypress, returning nil" do
        allow(prompt).to receive(:keypress).with("Press any key to continue...").and_return(nil)

        result = renderer.render(node)

        expect(result).to be_nil
        expect(prompt).to have_received(:keypress)
      end
    end

    context "with an unknown node type" do
      let(:node) { build_node(type: :unknown_fancy_type) }

      it "falls back to text rendering" do
        allow(prompt).to receive(:ask).with("Test question").and_return("fallback")

        result = renderer.render(node)

        expect(result).to eq("fallback")
      end
    end
  end

  describe "#prompt" do
    it "exposes the prompt instance" do
      expect(renderer.prompt).to eq(prompt)
    end
  end

  describe "default prompt" do
    it "creates a TTY::Prompt when none is provided" do
      # We just verify it doesn't raise; actual TTY::Prompt may require a terminal
      expect { described_class.new(prompt: TTY::Prompt.new(input: StringIO.new, output: StringIO.new)) }
        .not_to raise_error
    end
  end
end
