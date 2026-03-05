# frozen_string_literal: true

# Example 4: Event Registration
#
# Two levels of conditional logic. The ticket type determines one
# branch, and within VIP there's a further branch based on
# whether the guest wants a plus-one.
# Demonstrates: single_select, boolean, equals rule, two-level branching.
#
# Run:  bundle exec exe/flowengine-cli run examples/04_event_registration.rb

FlowEngine.define do
  start :attendee_name

  step :attendee_name do
    type :text
    question "What is your full name?"
    transition to: :ticket_type
  end

  step :ticket_type do
    type :single_select
    question "Select your ticket type:"
    options %w[General VIP Speaker]
    transition to: :vip_options, if_rule: equals(:ticket_type, "VIP")
    transition to: :talk_title, if_rule: equals(:ticket_type, "Speaker")
    transition to: :dietary
  end

  # --- VIP branch (level 1) ---

  step :vip_options do
    type :boolean
    question "Would you like to bring a plus-one?"
    transition to: :plus_one_name, if_rule: equals(:vip_options, true)
    transition to: :dietary
  end

  # VIP plus-one sub-branch (level 2)
  step :plus_one_name do
    type :text
    question "What is your plus-one's name?"
    transition to: :dietary
  end

  # --- Speaker branch (level 1) ---

  step :talk_title do
    type :text
    question "What is the title of your talk?"
    transition to: :av_needs
  end

  # Speaker AV sub-branch (level 2)
  step :av_needs do
    type :multi_select
    question "What A/V equipment do you need?"
    options %w[Projector Microphone Whiteboard ScreenShare None]
    transition to: :dietary
  end

  # --- Common path ---

  step :dietary do
    type :single_select
    question "Any dietary restrictions?"
    options %w[None Vegetarian Vegan GlutenFree Halal Kosher]
    transition to: :confirmation
  end

  step :confirmation do
    type :display
    question "You're registered! See you at the event."
  end
end
