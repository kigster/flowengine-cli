# frozen_string_literal: true

require "json"
require "tty-box"
require "tty-screen"

module FlowEngine
  module CLI
    module Commands
      # Runs a flow definition interactively via TTY prompts and writes the
      # collected answers (and metadata) as JSON to stdout or a file.
      class Run < Dry::CLI::Command
        desc "Run a flow definition interactively"

        argument :flow_file, required: true, desc: "Path to flow definition (.rb file)"
        option :output, aliases: ["-o"], desc: "Output file for JSON results"

        # @param flow_file [String] path to the flow definition .rb file
        # @param options [Hash] :output => path to write JSON (optional)
        # @return [void]
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

        # @param flow_file [String] path to flow definition
        # @return [FlowEngine::Engine] engine after completion
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

        # @param flow_file [String] path used to load the flow
        # @param engine [FlowEngine::Engine] completed engine
        # @return [Hash] result hash with flow_file, path_taken, answers, etc.
        def build_result(flow_file, engine)
          {
            flow_file: flow_file,
            path_taken: engine.history,
            answers: engine.answers,
            steps_completed: engine.history.length,
            completed_at: Time.now.iso8601
          }
        end

        # @param path [String] output file path
        # @param json_output [String] JSON string to write
        # @return [void]
        def write_output(path, json_output)
          File.write(path, json_output)
          puts "\nResults saved to #{path}"
        end
      end
    end
  end
end
