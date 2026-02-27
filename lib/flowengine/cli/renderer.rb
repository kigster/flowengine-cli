# frozen_string_literal: true

require "tty-prompt"

module FlowEngine
  module CLI
    class Renderer
      attr_reader :prompt

      def initialize(prompt: TTY::Prompt.new)
        @prompt = prompt
      end

      def render(node)
        method_name = :"render_#{node.type}"

        if respond_to?(method_name, true)
          send(method_name, node)
        else
          render_text(node)
        end
      end

      private

      def render_multi_select(node)
        prompt.multi_select(node.question, node.options, min: 1)
      end

      def render_single_select(node)
        prompt.select(node.question, node.options)
      end

      def render_number_matrix(node)
        puts "\n#{node.question}\n\n"
        result = {}
        node.fields.each do |field|
          result[field] = prompt.ask("  #{field}:", convert: :int, default: 0)
        end
        result
      end

      def render_text(node)
        prompt.ask(node.question)
      end

      def render_number(node)
        prompt.ask(node.question, convert: :int)
      end

      def render_boolean(node) # rubocop:disable Naming/PredicateMethod
        prompt.yes?(node.question)
      end

      def render_display(node)
        puts "\n#{node.question}\n"
        prompt.keypress("Press any key to continue...")
        nil
      end
    end
  end
end
