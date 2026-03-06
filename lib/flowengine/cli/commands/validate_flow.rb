# frozen_string_literal: true

module FlowEngine
  module CLI
    module Commands
      # Validates a flow definition file: start step exists, transitions point to
      # known steps, and all steps are reachable from the start step.
      class ValidateFlow < Dry::CLI::Command
        desc "Validate a flow definition file"

        argument :flow_file, required: true, desc: "Path to flow definition (.rb file)"

        # @param flow_file [String] path to the flow definition .rb file
        # @param **_ [Hash] ignored options
        # @return [void]
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

        # @param definition [FlowEngine::Definition]
        # @return [void]
        def print_success(definition)
          puts "Flow definition is valid!"
          puts "  Start step: #{definition.start_step_id}"
          puts "  Total steps: #{definition.step_ids.length}"
          puts "  Steps: #{definition.step_ids.join(", ")}"
        end

        # @param errors [Array<String>]
        # @return [void]
        def print_errors(errors)
          warn "Flow definition has errors:"
          errors.each { |e| warn "  - #{e}" }
        end

        # @param definition [FlowEngine::Definition]
        # @return [Array<String>] list of error messages
        def validate_definition(definition)
          errors = []

          validate_start_step(definition, errors)
          validate_transition_targets(definition, errors)
          validate_reachability(definition, errors)

          errors
        end

        # @param definition [FlowEngine::Definition]
        # @param errors [Array<String>] mutated with new errors
        # @return [void]
        def validate_start_step(definition, errors)
          return if definition.step_ids.include?(definition.start_step_id)

          errors << "Start step :#{definition.start_step_id} not found in steps"
        end

        # @param definition [FlowEngine::Definition]
        # @param errors [Array<String>] mutated with new errors
        # @return [void]
        def validate_transition_targets(definition, errors)
          definition.step_ids.each do |step_id|
            step = definition.step(step_id)
            step.transitions.each do |transition|
              next if definition.step_ids.include?(transition.target)

              errors << "Step :#{step_id} has transition to unknown step :#{transition.target}"
            end
          end
        end

        # @param definition [FlowEngine::Definition]
        # @param errors [Array<String>] mutated with new errors
        # @return [void]
        def validate_reachability(definition, errors)
          reachable = find_reachable_steps(definition)
          orphans = definition.step_ids - reachable

          orphans.each do |orphan|
            errors << "Step :#{orphan} is unreachable from start step :#{definition.start_step_id}"
          end
        end

        # @param definition [FlowEngine::Definition]
        # @return [Array<Symbol>] step ids reachable from start
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

        # @param step [FlowEngine::Node]
        # @param known_ids [Array<Symbol>]
        # @param queue [Array] mutated with transition targets
        # @return [void]
        def enqueue_transitions(step, known_ids, queue)
          step.transitions.each do |t|
            queue << t.target if known_ids.include?(t.target)
          end
        end
      end
    end
  end
end
