# frozen_string_literal: true

# Example 3: Food Preferences
#
# Multiple independent branches from a single multi_select step.
# Each selection may activate a different follow-up question.
# Demonstrates: multi_select, contains rule, multiple transitions.
#
# Run:  bundle exec exe/flowengine-cli run examples/03_food_preferences.rb

FlowEngine.define do
  start :diet

  step :diet do
    type :multi_select
    question "Which food categories do you enjoy?"
    options %w[Meat Seafood Vegetarian Vegan Dessert]
    transition to: :meat_preference, if_rule: contains(:diet, "Meat")
    transition to: :seafood_preference, if_rule: contains(:diet, "Seafood")
    transition to: :dessert_preference, if_rule: contains(:diet, "Dessert")
    transition to: :summary
  end

  step :meat_preference do
    type :single_select
    question "What is your favorite type of meat?"
    options %w[Beef Chicken Pork Lamb]
    transition to: :seafood_preference, if_rule: contains(:diet, "Seafood")
    transition to: :dessert_preference, if_rule: contains(:diet, "Dessert")
    transition to: :summary
  end

  step :seafood_preference do
    type :single_select
    question "What is your favorite type of seafood?"
    options %w[Salmon Tuna Shrimp Lobster Crab]
    transition to: :dessert_preference, if_rule: contains(:diet, "Dessert")
    transition to: :summary
  end

  step :dessert_preference do
    type :single_select
    question "What is your favorite dessert?"
    options %w[Cake IceCream Pie Cookies Fruit]
    transition to: :summary
  end

  step :summary do
    type :display
    question "Thanks! We've noted your food preferences."
  end
end
