# rubocop:disable Metrics/BlockLength
# frozen_string_literal: true

require "flowengine"

# Example 8: Tax Preparer
#
# This example demonstrates a more complex flow
# with multiple levels of branching and conditional logic.
# Run: flow run examples/08_tax_preparer.rb

FlowEngine.define do
  introduction label: "Please describe your tax situation in a few sentences.\n" \
                      "Do not under no circumstances provide any personal information,\n" \
                      "such as your address, or a social security number.\n",
    placeholder: "Example: I have two W-2s from my two jobs, a rental property and a side business hassle",
    maxlength: 2000

  start :filing_status

  step :filing_status do
    type :single_select
    question "What is your filing status for 2025?"
    options({
      "single" => "Single",
      "married_filing_jointly" => "Married Filing Jointly",
      "married_filing_separately" => "Married Filing Separately",
      "head_of_household" => "Head of Household",
      "widowed" => "Widowed"
    })
    transition to: :dependents
  end

  step :dependents do
    type :number
    question "How many dependents do you have?"
    transition to: :income_types
  end

  step :income_types do
    type :multi_select
    question "Select all income types that apply to you in 2025."
    options %w[W2 1099 Business Investment Rental Retirement]
    transition to: :business_count, if_rule: contains(:income_types, "Business")
    transition to: :investment_details, if_rule: contains(:income_types, "Investment")
    transition to: :rental_details, if_rule: contains(:income_types, "Rental")
    transition to: :state_filing
  end

  step :business_count do
    type :number
    question "How many total businesses do you own or are a partner in?"
    transition to: :complex_business_info, if_rule: greater_than(:business_count, 2)
    transition to: :business_details
  end

  step :complex_business_info do
    type :text
    question "With more than 2 businesses, please provide your primary EIN and a brief description of each entity."
    transition to: :business_details
  end

  step :business_details do
    type :number_matrix
    question "How many of each business type do you own?"
    fields %w[RealEstate SCorp CCorp Trust LLC]
    transition to: :investment_details, if_rule: contains(:income_types, "Investment")
    transition to: :rental_details, if_rule: contains(:income_types, "Rental")
    transition to: :state_filing
  end

  step :investment_details do
    type :multi_select
    question "What types of investments do you hold?"
    options %w[Stocks Bonds Crypto RealEstate MutualFunds]
    transition to: :crypto_details, if_rule: contains(:investment_details, "Crypto")
    transition to: :rental_details, if_rule: contains(:income_types, "Rental")
    transition to: :state_filing
  end

  step :crypto_details do
    type :text
    question "Please describe your cryptocurrency transactions (exchanges used, approximate number of transactions)."
    transition to: :rental_details, if_rule: contains(:income_types, "Rental")
    transition to: :state_filing
  end

  step :rental_details do
    type :number_matrix
    question "Provide details about your rental properties."
    fields %w[Residential Commercial Vacation]
    transition to: :state_filing
  end

  step :state_filing do
    type :multi_select
    question "Which states do you need to file in?"
    options %w[California NewYork Texas Florida Illinois Other]
    transition to: :foreign_accounts
  end

  step :foreign_accounts do
    type :single_select
    question "Do you have any foreign financial accounts (bank accounts, securities, or financial assets)?"
    options %w[yes no]
    transition to: :foreign_account_details, if_rule: equals(:foreign_accounts, "yes")
    transition to: :deduction_types
  end

  step :foreign_account_details do
    type :number
    question "How many foreign accounts do you have?"
    transition to: :deduction_types
  end

  step :deduction_types do
    type :multi_select
    question "Which additional deductions apply to you?"
    options %w[Medical Charitable Education Mortgage None]
    transition to: :charitable_amount, if_rule: contains(:deduction_types, "Charitable")
    transition to: :contact_info
  end

  step :charitable_contribution do
    type :single_select
    question "Do you have any charitable contributions over $5,000 with receipts?"
    options %w[yes no]
    transition to: :charitable_documentation, if_rule: greater_than(:charitable_amount, 5000)
    transition to: :contact_info
  end

  step :charitable_amount do
    type :number
    question "How much did you donate to charity in 2025 (over $5,000)?"
    transition to: :charitable_documentation, if_rule: greater_than(:charitable_amount, 5000)
  end

  step :charitable_documentation do
    type :textarea
    question "For charitable contributions over $5,000, please describe what sort of paperwork you have available."
  end

  step :thanks do
    type :display
    question "Thank you! Your tax preparation is complete. The last step remaining is " \
             "to get your name and email so that we can send you our tax preparation estimate."
    transition to: :review
  end

  step :name do
    type :text
    question "Your Name Please:"
  end

  step :email do
    type :text
    question "Your Email Please:"
    transition to: :review
  end

  step :finish do
    type :display
    question "Thank you! Press Continue and you'll get an email from us " \
             "with your tax preparation estimate. We thank you for your business!"
  end
end

# rubocop:enable Metrics/BlockLength
