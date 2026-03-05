# This is the first example in the README

FlowEngine.define do
  start :filing_status

  step :filing_status do
    type :single_select
    question "What is your filing status?"
    options %w[Single Married HeadOfHousehold]
    transition to: :income_types
  end

  step :income_types do
    type :multi_select
    question "Select all income types that apply:"
    options %w[W2 1099 Business Investment Rental]
    transition to: :business_details, if_rule: contains(:income_types, "Business")
    transition to: :summary
  end

  step :business_details do
    type :number_matrix
    question "How many of each business type?"
    fields %w[LLC SCorp CCorp]
    transition to: :summary
  end

  step :summary do
    type :display_fancy
    decorations("Success!")
    question "Thank you for completing the intake!"
  end
end
