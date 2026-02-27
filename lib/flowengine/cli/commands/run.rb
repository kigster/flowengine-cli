# frozen_string_literal: true

require "json"
require "tty-box"
require "tty-screen"

module FlowEngine
  module CLI
    module Commands
      class Run < Dry::CLI::Command
        desc "Run a flow definition interactively"

        argument :flow_file, required: true, desc: "Path to flow definition (.rb file)"
        option :output, aliases: ["-o"], desc: "Output file for JSON results"

        def call(flow_file:, **options)
          engine = run_flow(flow_file)
          json_output = JSON.pretty_generate(build_result(flow_file, engine))

          display_success("Flow completed!")
          puts json_output

          write_output(options[:output], json_output) if options[:output]
        rescue FlowEngine::CLI::Error => e
          display_error(e.message)
          exit 1
        rescue FlowEngine::Error => e
          display_error("Engine error: #{e.message}")
          exit 1
        end

        private

        def run_flow(flow_file)
          definition = FlowLoader.load(flow_file)
          engine = FlowEngine::Engine.new(definition)
          renderer = Renderer.new

          display_header("FlowEngine Interactive Wizard")

          until engine.finished?
            display_step_indicator(engine.current_step_id, engine.history.length)
            engine.answer(renderer.render(engine.current_step))
          end

          engine
        end

        def build_result(flow_file, engine)
          {
            flow_file: flow_file,
            path_taken: engine.history,
            answers: engine.answers,
            steps_completed: engine.history.length,
            completed_at: Time.now.iso8601
          }
        end

        def write_output(path, json_output)
          File.write(path, json_output)
          puts "\nResults saved to #{path}"
        end

        def display_header(text)
          width = [TTY::Screen.width, 80].min
          puts TTY::Box.frame(text, width: width, padding: 1, align: :center, border: :thick)
        end

        def display_step_indicator(step_id, step_number)
          puts "\n  Step #{step_number}: #{step_id}"
          puts "  #{"─" * 40}"
        end

        def display_success(text)
          width = [TTY::Screen.width, 80].min
          puts TTY::Box.frame(text, width: width, padding: 1, align: :center, title: { top_left: " SUCCESS " })
        end

        def display_error(text)
          width = [TTY::Screen.width, 80].min
          puts TTY::Box.frame(text, width: width, padding: 1, align: :center, title: { top_left: " ERROR " })
        end
      end
    end
  end
end
