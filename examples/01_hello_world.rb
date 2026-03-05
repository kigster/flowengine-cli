# frozen_string_literal: true

# Example 1: Hello World
#
# The simplest possible flow — three linear steps, no branching.
# Demonstrates: text input, number input, display output.
#
# Run:  bundle exec exe/flowengine-cli run examples/01_hello_world.rb

FlowEngine.define do
  start :name

  step :name do
    type :text
    question "What is your name?"
    transition to: :age
  end

  step :age do
    type :number
    question "How old are you?"
    transition to: :farewell
  end

  step :farewell do
    type :display
    question "Thanks for stopping by! Have a great day."
  end
end
