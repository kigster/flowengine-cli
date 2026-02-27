# frozen_string_literal: true

module FlowEngine
  module CLI
    module Commands
      class ValidateFlow < Dry::CLI::Command
        desc "Validate a flow definition file"

        argument :flow_file, required: true, desc: "Path to flow definition (.rb file)"

        def call(flow_file:, **)
          definition = FlowLoader.load(flow_file)
          errors = validate_definition(definition)

          if errors.empty?
            print_success(definition)
          else
            print_errors(errors)
            exit 1
          end
        rescue FlowEngine::CLI::Error => e
          warn "Error: #{e.message}"
          exit 1
        rescue FlowEngine::Error => e
          warn "Definition error: #{e.message}"
          exit 1
        end

        private

        def print_success(definition)
          puts "Flow definition is valid!"
          puts "  Start step: #{definition.start_step_id}"
          puts "  Total steps: #{definition.step_ids.length}"
          puts "  Steps: #{definition.step_ids.join(", ")}"
        end

        def print_errors(errors)
          warn "Flow definition has errors:"
          errors.each { |e| warn "  - #{e}" }
        end

        def validate_definition(definition)
          errors = []

          validate_start_step(definition, errors)
          validate_transition_targets(definition, errors)
          validate_reachability(definition, errors)

          errors
        end

        def validate_start_step(definition, errors)
          return if definition.step_ids.include?(definition.start_step_id)

          errors << "Start step :#{definition.start_step_id} not found in steps"
        end

        def validate_transition_targets(definition, errors)
          definition.step_ids.each do |step_id|
            step = definition.step(step_id)
            step.transitions.each do |transition|
              next if definition.step_ids.include?(transition.target)

              errors << "Step :#{step_id} has transition to unknown step :#{transition.target}"
            end
          end
        end

        def validate_reachability(definition, errors)
          reachable = find_reachable_steps(definition)
          orphans = definition.step_ids - reachable

          orphans.each do |orphan|
            errors << "Step :#{orphan} is unreachable from start step :#{definition.start_step_id}"
          end
        end

        def find_reachable_steps(definition)
          visited = Set.new
          queue = [definition.start_step_id]
          known_ids = definition.step_ids

          until queue.empty?
            current = queue.shift
            next if visited.include?(current)

            visited << current
            next unless known_ids.include?(current)

            enqueue_transitions(definition.step(current), known_ids, queue)
          end

          visited.to_a
        end

        def enqueue_transitions(step, known_ids, queue)
          step.transitions.each do |t|
            queue << t.target if known_ids.include?(t.target)
          end
        end
      end
    end
  end
end
