# frozen_string_literal: true

FlowEngine.define do
  start :filing_status

  introduction label: "Tell us about your tax situation",
    placeholder: "e.g. I am married, filing jointly, with 2 dependents...",
    maxlength: 500

  step :filing_status do
    type :single_select
    question "What is your filing status?"
    options %w[single married_filing_jointly head_of_household]
    transition to: :dependents
  end

  step :dependents do
    type :number
    question "How many dependents do you have?"
    transition to: :done
  end

  step :done do
    type :display
    question "Thank you!"
  end
end
