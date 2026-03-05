# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength, Metrics/AbcSize

require "forwardable"
require "tty-box"
require "tty-screen"
require "pastel"

module FlowEngine
  module CLI
    module UIHelper
      class << self
        def pastel
          @pastel ||= Pastel.new
        end

        def included(base)
          base.extend(Forwardable)
          # Forwardable needs an accessor (method returning the target).
          # :TTY::Box / :TTY::Screen are not valid method names on the instance.
          base.define_method(:tty_box) { ::TTY::Box }
          base.define_method(:tty_screen) { ::TTY::Screen }
          base.define_method(:pastel) { ::FlowEngine::CLI::UIHelper.pastel }

          # TTY::Box uses :warn, not :warning
          %i[frame info success error].each do |method|
            base.define_method(method) { |*args, **kwargs| puts ::TTY::Box.send(method, *args, **kwargs) }
          end
          base.define_method(:warning) { |*args, **kwargs| puts ::TTY::Box.send(:warn, *args, **kwargs) }

          base.def_delegators :tty_screen, :width

          base.class_eval do
            def box(text, title: nil, bg: :green, fg: :white) # rubocop:disable Naming/MethodParameterName
              width = [width(), 80].min
              args = {
                width: width,
                padding: { top: 0, bottom: 0, left: 1, right: 1 },
                align: :center,
                style: { fg: fg,
                         bg: bg,
                         border: { type: :thin, fg: fg, bg: bg } }
              }
              args[:title] = { top_left: title } if title
              frame(text, **args)
            end

            def next_step(step_id, step_number)
              puts pastel.yellow("Step #{step_number}: #{step_id}")
              sep(:yellow, "━")
            end

            def sep(color = :yellow, char = "▪")
              puts pastel.send(color, (char * 80).to_s)
            end
          end
        end
      end
    end
  end
end

# rubocop:enable Metrics/MethodLength, Metrics/AbcSize
