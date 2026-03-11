# frozen_string_literal: true

RSpec.describe FlowEngine::CLI::Renderer do
  subject(:renderer) { described_class.new(prompt: mock_prompt) }

  let(:mock_prompt) { instance_double(TTY::Prompt) }

  before do
    # Suppress all puts/print output
    allow($stdout).to receive(:write)
    allow($stdout).to receive(:puts)
  end

  describe "#render" do
    context "with a text step" do
      let(:node) { instance_double(FlowEngine::Node, type: :text, question: "Your name?") }

      before { allow(mock_prompt).to receive(:ask).with("Your name?").and_return("Alice") }

      it { expect(renderer.render(node)).to eq("Alice") }
    end

    context "with a number step" do
      let(:node) { instance_double(FlowEngine::Node, type: :number, question: "How old?") }

      before { allow(mock_prompt).to receive(:ask).with("How old?", convert: :int).and_return(30) }

      it { expect(renderer.render(node)).to eq(30) }
    end

    context "with a single_select step" do
      let(:node) do
        instance_double(FlowEngine::Node, type: :single_select,
          question: "Pick one:", options: %w[A B C], option_labels: nil)
      end

      before { allow(mock_prompt).to receive(:select).with("Pick one:", %w[A B C]).and_return("B") }

      it { expect(renderer.render(node)).to eq("B") }
    end

    context "with a single_select step with option labels" do
      let(:node) do
        instance_double(FlowEngine::Node, type: :single_select,
          question: "Pick one:", options: %w[a b],
          option_labels: { "a" => "Label A", "b" => "Label B" })
      end

      before do
        allow(mock_prompt).to receive(:select)
          .with("Pick one:", { "a" => "Label A", "b" => "Label B" }).and_return("a")
      end

      it { expect(renderer.render(node)).to eq("a") }
    end

    context "with a multi_select step" do
      let(:node) do
        instance_double(FlowEngine::Node, type: :multi_select,
          question: "Select:", options: %w[X Y Z], option_labels: nil)
      end

      before do
        allow(mock_prompt).to receive(:multi_select).with("Select:", %w[X Y Z], min: 1)
                                                    .and_return(%w[X Z])
      end

      it { expect(renderer.render(node)).to eq(%w[X Z]) }
    end

    context "with a boolean step" do
      let(:node) { instance_double(FlowEngine::Node, type: :boolean, question: "Continue?") }

      before { allow(mock_prompt).to receive(:yes?).with("Continue?").and_return(true) }

      it { expect(renderer.render(node)).to be true }
    end

    context "with a number_matrix step" do
      let(:node) do
        instance_double(FlowEngine::Node, type: :number_matrix,
          question: "How many?", fields: %w[LLC SCorp])
      end

      before do
        allow(mock_prompt).to receive(:ask).with("  LLC:", convert: :int, default: 0).and_return(2)
        allow(mock_prompt).to receive(:ask).with("  SCorp:", convert: :int, default: 0).and_return(1)
      end

      it { expect(renderer.render(node)).to eq({ "LLC" => 2, "SCorp" => 1 }) }
    end

    context "with a display step" do
      let(:node) { instance_double(FlowEngine::Node, type: :display, question: "All done!") }

      before { allow(mock_prompt).to receive(:keypress) }

      it { expect(renderer.render(node)).to be_nil }
    end

    context "with an unknown step type" do
      let(:node) { instance_double(FlowEngine::Node, type: :fancy_widget, question: "Fancy?") }

      before { allow(mock_prompt).to receive(:ask).with("Fancy?").and_return("something") }

      it "falls back to text rendering" do
        expect(renderer.render(node)).to eq("something")
      end
    end
  end

  describe "#render_introduction" do
    let(:introduction) do
      FlowEngine::Introduction.new(
        label: "Describe your situation",
        placeholder: "e.g. I am married...",
        maxlength: 500
      )
    end

    context "when user provides text" do
      before do
        call_count = 0
        allow(mock_prompt).to receive(:ask) do
          call_count += 1
          call_count == 1 ? "I am single with W2 income" : nil
        end
      end

      it "returns the collected text" do
        expect(renderer.render_introduction(introduction)).to eq("I am single with W2 income")
      end
    end

    context "when user provides multiline text" do
      before do
        lines = ["I am married", "filing jointly", "two dependents", nil]
        call_index = 0
        allow(mock_prompt).to receive(:ask) do
          line = lines[call_index]
          call_index += 1
          line
        end
      end

      it "joins lines with newlines" do
        expect(renderer.render_introduction(introduction)).to eq(
          "I am married\nfiling jointly\ntwo dependents"
        )
      end
    end

    context "when user presses enter immediately (skips)" do
      before do
        allow(mock_prompt).to receive(:ask).and_return(nil)
      end

      it { expect(renderer.render_introduction(introduction)).to be_nil }
    end

    context "when text exceeds maxlength" do
      let(:introduction) do
        FlowEngine::Introduction.new(label: "Describe", placeholder: "", maxlength: 20)
      end

      before do
        lines = ["short text", "this line makes it exceed the limit", nil]
        call_index = 0
        allow(mock_prompt).to receive(:ask) do
          line = lines[call_index]
          call_index += 1
          line
        end
      end

      it "removes the overflowing line and returns valid text" do
        expect(renderer.render_introduction(introduction)).to eq("short text")
      end
    end

    context "with no placeholder" do
      let(:introduction) do
        FlowEngine::Introduction.new(label: "Describe", placeholder: "", maxlength: nil)
      end

      before do
        allow(mock_prompt).to receive(:ask).and_return("some text", nil)
      end

      it "returns the text" do
        expect(renderer.render_introduction(introduction)).to eq("some text")
      end
    end

    context "with no maxlength" do
      let(:introduction) do
        FlowEngine::Introduction.new(label: "Describe", placeholder: "hint", maxlength: nil)
      end

      before do
        allow(mock_prompt).to receive(:ask).and_return("text", nil)
      end

      it "returns collected text without length enforcement" do
        expect(renderer.render_introduction(introduction)).to eq("text")
      end
    end
  end
end
