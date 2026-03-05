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

          if options[:output]
            write_output(options[:output], json_output)
          else
            $stderr.puts json_output # rubocop:disable Style/StderrPuts
          end
        rescue FlowEngine::CLI::Error => e
          error(e.message)
          exit 1
        rescue FlowEngine::Error => e
          error("Engine error: #{e.message}")
          exit 1
        end

        private

        def run_flow(flow_file)
          definition = FlowLoader.load(flow_file)
          engine = FlowEngine::Engine.new(definition)
          renderer = Renderer.new

          box("FlowEngine Interactive Wizard")

          until engine.finished?
            next_step(engine.current_step_id, engine.history.length)
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
      end
    end
  end
end
