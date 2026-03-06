# frozen_string_literal: true

module FlowEngine
  module CLI
    module Commands
      # Exports a flow definition as a Mermaid flowchart (stdout or file).
      class Graph < Dry::CLI::Command
        desc "Export a flow definition as a Mermaid diagram"

        argument :flow_file, required: true, desc: "Path to flow definition (.rb file)"
        option :output, aliases: ["-o"], desc: "Output file (default: stdout)"
        option :format, default: "mermaid", desc: "Output format (mermaid)"

        # @param flow_file [String] path to the flow definition .rb file
        # @param options [Hash] :output => path to write diagram, :format => "mermaid"
        # @return [void]
        def call(flow_file:, **options)
          definition = FlowLoader.load(flow_file)

          mermaid = FlowEngine::Graph::MermaidExporter.new(definition).export

          if options[:output]
            File.write(options[:output], mermaid)
            warn "Diagram written to #{options[:output]}"
          else
            puts mermaid
          end
        rescue FlowEngine::CLI::Error => e
          warn "Error: #{e.message}"
          exit 1
        end
      end
    end
  end
end
