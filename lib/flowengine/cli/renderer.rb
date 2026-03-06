# frozen_string_literal: true

require "tty-prompt"
require_relative "ui_helper"

module FlowEngine
  module CLI
    # Renders flow steps as TTY prompts. Dispatches to a type-specific renderer
    # (e.g. +render_multi_select+, +render_single_select+) or falls back to
    # +render_text+ for unknown node types.
    class Renderer
      # @return [TTY::Prompt] the TTY prompt instance used for input
      attr_reader :prompt

      include ::FlowEngine::CLI::UIHelper

      # @param prompt [TTY::Prompt] prompt instance (default: new TTY::Prompt)
      def initialize(prompt: TTY::Prompt.new)
        @prompt = prompt
      end

      # Renders a single step node and returns the user's answer.
      # @param node [FlowEngine::Node] the current step node from the flow definition
      # @return [Object] answer value (String, Integer, Boolean, Array, Hash, or nil)
      def render(node)
        method_name = :"render_#{node.type}"

        if respond_to?(method_name, true)
          send(method_name, node)
        else
          render_text(node)
        end
      end

      private

      # @param node [FlowEngine::Node] multi_select step
      # @return [Array<String>]
      def render_multi_select(node)
        prompt.multi_select(node.question, node.options, min: 1)
      end

      # @param node [FlowEngine::Node] single_select step
      # @return [String]
      def render_single_select(node)
        prompt.select(node.question, node.options)
      end

      # @param node [FlowEngine::Node] number_matrix step
      # @return [Hash<String, Integer>]
      def render_number_matrix(node)
        puts "\n#{node.question}\n\n"
        result = {}
        node.fields.each do |field|
          result[field] = prompt.ask("  #{field}:", convert: :int, default: 0)
        end
        result
      end

      # @param node [FlowEngine::Node] text step
      # @return [String, nil]
      def render_text(node)
        prompt.ask(node.question)
      end

      # @param node [FlowEngine::Node] number step
      # @return [Integer, nil]
      def render_number(node)
        prompt.ask(node.question, convert: :int)
      end

      # @param node [FlowEngine::Node] boolean step
      # @return [Boolean]
      def render_boolean(node) # rubocop:disable Naming/PredicateMethod
        prompt.yes?(node.question)
      end

      # @param node [FlowEngine::Node] display step (informational, no answer)
      # @return [nil]
      def render_display(node)
        puts "\n#{node.question}\n"
        prompt.keypress("Press any key to continue...")
        sep(:green, "━")
        nil
      end

      # Renders a header node with a title and a separator.
      # @param node [FlowEngine::Node] header step (optional decorations)
      # @return [nil]
      def render_header(node)
        title = node.respond_to?(:decorations) ? node.decorations : nil
        opts = {}
        opts[:title] = { style: { top_left: title } } if title
        puts box(node.question, bg: :blue, fg: :white, **opts)
        puts node.question
        prompt.keypress("Press any key to continue...")
        sep(:green, "━")
        nil
      end
    end
  end
end
