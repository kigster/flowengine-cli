# frozen_string_literal: true

FlowEngine.define do
  start :greeting

  step :greeting do
    type :single_select
    question "What would you like to do?"
    options %w[FileReturn GetEstimate LearnMore]
    transition to: :income_info, if_rule: equals(:greeting, "FileReturn")
    transition to: :estimate, if_rule: equals(:greeting, "GetEstimate")
    transition to: :info
  end

  step :income_info do
    type :multi_select
    question "Select your income types:"
    options %w[W2 1099 Business Investment]
    transition to: :business_details, if_rule: contains(:income_info, "Business")
    transition to: :summary
  end

  step :business_details do
    type :number_matrix
    question "How many businesses?"
    fields %w[LLC SCorp CCorp]
    transition to: :summary
  end

  step :estimate do
    type :text
    question "Describe your tax situation briefly:"
    transition to: :summary
  end

  step :info do
    type :display
    question "Visit our website for more information."
  end

  step :summary do
    type :display
    question "Thank you for completing the intake!"
  end
end
