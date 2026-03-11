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
        desc "Run a flow definition interactively, to choose an LLM specify it's API Key"

        argument :flow_file, required: true, desc: "Path to flow definition (.rb file)"
        option :output, aliases: ["-o"], desc: "Output file for JSON results"
        option :skip_introduction, aliases: ["-s"], type: :boolean, default: false,
          desc: "Skip the introduction prompt even if defined"

        # @param flow_file [String] path to the flow definition .rb file
        # @param options [Hash] CLI options
        # @return [void]
        def call(flow_file:, **options)
          engine = run_flow(flow_file, **options)
          json_output = JSON.pretty_generate(build_result(flow_file, engine))

          if options[:output]
            write_output(options[:output], json_output)
          else
            $stderr.puts json_output # rubocop:disable Style/StderrPuts
          end
        rescue FlowEngine::CLI::Error => e
          error(e.message)
          exit 1
        rescue FlowEngine::Errors::Error => e
          error("Engine error: #{e.message}")
          exit 1
        end

        private

        # @param flow_file [String] path to flow definition
        # @param options [Hash] CLI options (provider, model, api_key, skip_introduction)
        # @return [FlowEngine::Engine] engine after completion
        def run_flow(flow_file, **options)
          definition = FlowLoader.load(flow_file)
          engine = FlowEngine::Engine.new(definition)
          renderer = Renderer.new

          box("FlowEngine Interactive Wizard")

          handle_introduction(engine, renderer, **options) if show_introduction?(definition, options)

          until engine.finished?
            next_step(engine.current_step_id, engine.history.length + 1)
            engine.answer(renderer.render(engine.current_step))
          end

          engine
        end

        # @param definition [FlowEngine::Definition]
        # @param options [Hash]
        # @return [Boolean]
        def show_introduction?(definition, options)
          definition.introduction && !options[:skip_introduction]
        end

        # Prompts for introduction text, optionally parses it via LLM.
        # @param engine [FlowEngine::Engine]
        # @param renderer [Renderer]
        # @param options [Hash] provider, model, api_key
        def handle_introduction(engine, renderer, **)
          intro = engine.definition.introduction
          text = renderer.render_introduction(intro)
          return if text.nil? || text.strip.empty?

          llm_client = build_llm_client(**)
          if llm_client
            submit_with_llm(engine, text, llm_client)
          else
            warning("No LLM API key found. Introduction text saved but answers not pre-filled.")
            engine.instance_variable_set(:@introduction_text, text)
          end
        end

        # Calls engine.submit_introduction with error handling.
        # @param engine [FlowEngine::Engine]
        # @param text [String]
        # @param llm_client [FlowEngine::LLM::Client]
        def submit_with_llm(engine, text, llm_client)
          engine.submit_introduction(text, llm_client: llm_client)
          skipped = engine.answers.keys & engine.history.map(&:to_sym)
          return if skipped.empty?

          info("LLM pre-filled #{skipped.length} answer(s) from your introduction.")
        rescue FlowEngine::Errors::SensitiveDataError => e
          warning("Sensitive data detected: #{e.message}\nIntroduction discarded. Proceeding with all steps.")
        rescue FlowEngine::Errors::ValidationError => e
          warning("Introduction validation failed: #{e.message}\nProceeding with all steps.")
        rescue FlowEngine::Errors::LLMError => e
          warning("LLM error: #{e.message}\nProceeding with all steps.")
        end

        # Builds an LLM client if an API key is available.
        # @return [FlowEngine::LLM::Client, nil]
        def build_llm_client(**)
          FlowEngine::LLM.auto_client(
            anthropic_api_key: ENV.fetch("ANTHROPIC_API_KEY", nil),
            gemini_api_key: ENV.fetch("GEMINI_API_KEY", nil),
            openai_api_key: ENV.fetch("OPENAI_API_KEY", nil)
          )
        rescue FlowEngine::Errors::LLMError
          nil
        end

        # @param flow_file [String] path used to load the flow
        # @param engine [FlowEngine::Engine] completed engine
        # @return [Hash] result hash with flow_file, path_taken, answers, etc.
        def build_result(flow_file, engine)
          result = {
            flow_file: flow_file,
            path_taken: engine.history,
            answers: engine.answers,
            steps_completed: engine.history.length,
            completed_at: Time.now.iso8601
          }
          result[:introduction_text] = engine.introduction_text if engine.introduction_text
          result
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
