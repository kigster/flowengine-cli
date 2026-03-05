# frozen_string_literal: true

# Example 2: Yes or No
#
# A single boolean branch. Answering "yes" takes a detour;
# answering "no" goes straight to the end.
# Demonstrates: boolean step, equals rule, simple branching.
#
# Run:  bundle exec exe/flowengine-cli run examples/02_yes_or_no.rb

FlowEngine.define do
  start :has_pet

  step :has_pet do
    type :boolean
    question "Do you have a pet?"
    transition to: :pet_name, if_rule: equals(:has_pet, true)
    transition to: :done
  end

  step :pet_name do
    type :text
    question "What is your pet's name?"
    transition to: :done
  end

  step :done do
    type :display
    question "All done! Thanks for answering."
  end
end
