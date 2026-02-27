# frozen_string_literal: true

require "tempfile"

RSpec.describe FlowEngine::CLI::Commands::ValidateFlow do
  let(:fixture_path) { File.expand_path("../../../fixtures/sample_flow.rb", __dir__) }

  describe "#call" do
    context "with a valid flow" do
      it "prints success message" do
        expect { subject.call(flow_file: fixture_path) }.to output(/Flow definition is valid!/).to_stdout
      end

      it "prints the start step" do
        expect { subject.call(flow_file: fixture_path) }.to output(/Start step: greeting/).to_stdout
      end

      it "prints the total steps count" do
        expect { subject.call(flow_file: fixture_path) }.to output(/Total steps: 6/).to_stdout
      end

      it "prints the step names" do
        expect { subject.call(flow_file: fixture_path) }.to output(/greeting/).to_stdout
      end
    end

    context "with a flow containing unreachable steps" do
      let(:flow_with_orphan) do
        tmpfile = Tempfile.new(["flow", ".rb"])
        tmpfile.write(<<~RUBY)
          FlowEngine.define do
            start :step_a

            step :step_a do
              type :text
              question "First step"
              transition to: :step_b
            end

            step :step_b do
              type :text
              question "Second step"
            end

            step :orphan do
              type :text
              question "I am unreachable"
            end
          end
        RUBY
        tmpfile.close
        tmpfile
      end

      after { flow_with_orphan.unlink }

      it "reports unreachable steps" do
        expect do
          subject.call(flow_file: flow_with_orphan.path)
        rescue SystemExit
          # expected
        end.to output(/unreachable/).to_stderr
      end

      it "exits with status 1" do
        expect do
          subject.call(flow_file: flow_with_orphan.path)
        end.to raise_error(SystemExit) { |e| expect(e.status).to eq(1) }
      end
    end

    context "with a non-existent file" do
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

    context "when FlowEngine::Error is raised" do
      it "catches the error and exits with status 1" do
        allow(FlowEngine::CLI::FlowLoader).to receive(:load)
          .and_raise(FlowEngine::DefinitionError, "bad definition")

        expect do
          subject.call(flow_file: fixture_path)
        end.to raise_error(SystemExit) { |e| expect(e.status).to eq(1) }
      end

      it "prints definition error message to stderr" do
        allow(FlowEngine::CLI::FlowLoader).to receive(:load)
          .and_raise(FlowEngine::DefinitionError, "bad definition")

        expect do
          subject.call(flow_file: fixture_path)
        rescue SystemExit
          # expected
        end.to output(/Definition error: bad definition/).to_stderr
      end
    end
  end

  describe "validation logic" do
    let(:validator) { described_class.new }

    describe "validate_transition_targets" do
      it "reports transitions to unknown steps" do
        # Build mock objects that aren't frozen
        bad_transition = instance_double(FlowEngine::Transition, target: :unknown_step)
        step_a = instance_double(FlowEngine::Node, transitions: [bad_transition])
        definition = instance_double(
          FlowEngine::Definition,
          step_ids: [:step_a],
          start_step_id: :step_a,
          step: step_a
        )

        errors = []
        validator.send(:validate_transition_targets, definition, errors)

        expect(errors).to include(/transition to unknown step :unknown_step/)
      end

      it "does not report valid transitions" do
        valid_transition = instance_double(FlowEngine::Transition, target: :step_b)
        step_a = instance_double(FlowEngine::Node, transitions: [valid_transition])
        definition = instance_double(
          FlowEngine::Definition,
          step_ids: %i[step_a step_b],
          start_step_id: :step_a
        )
        allow(definition).to receive(:step).with(:step_a).and_return(step_a)
        step_b = instance_double(FlowEngine::Node, transitions: [])
        allow(definition).to receive(:step).with(:step_b).and_return(step_b)

        errors = []
        validator.send(:validate_transition_targets, definition, errors)

        expect(errors).to be_empty
      end
    end

    describe "validate_start_step" do
      it "reports when start step is not in step_ids" do
        definition = instance_double(
          FlowEngine::Definition,
          step_ids: [:step_b],
          start_step_id: :step_a
        )

        errors = []
        validator.send(:validate_start_step, definition, errors)

        expect(errors).to include(/Start step :step_a not found/)
      end

      it "does not report when start step exists" do
        definition = instance_double(
          FlowEngine::Definition,
          step_ids: [:step_a],
          start_step_id: :step_a
        )

        errors = []
        validator.send(:validate_start_step, definition, errors)

        expect(errors).to be_empty
      end
    end

    describe "find_reachable_steps" do
      it "skips transition targets not in step_ids" do
        # Transition points to :unknown which is NOT in step_ids
        # Line 88: queue << t.target if definition.step_ids.include?(t.target)
        # The else branch: target is NOT queued
        transition_to_unknown = instance_double(FlowEngine::Transition, target: :unknown)
        step_a = instance_double(FlowEngine::Node, transitions: [transition_to_unknown])
        definition = instance_double(
          FlowEngine::Definition,
          step_ids: [:step_a],
          start_step_id: :step_a
        )
        allow(definition).to receive(:step).with(:step_a).and_return(step_a)

        reachable = validator.send(:find_reachable_steps, definition)

        expect(reachable).to eq([:step_a])
        expect(reachable).not_to include(:unknown)
      end

      it "queues transition targets that are in step_ids" do
        transition = instance_double(FlowEngine::Transition, target: :step_b)
        step_a = instance_double(FlowEngine::Node, transitions: [transition])
        step_b = instance_double(FlowEngine::Node, transitions: [])
        definition = instance_double(
          FlowEngine::Definition,
          step_ids: %i[step_a step_b],
          start_step_id: :step_a
        )
        allow(definition).to receive(:step).with(:step_a).and_return(step_a)
        allow(definition).to receive(:step).with(:step_b).and_return(step_b)

        reachable = validator.send(:find_reachable_steps, definition)

        expect(reachable).to contain_exactly(:step_a, :step_b)
      end
    end
  end
end
