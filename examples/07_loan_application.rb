# frozen_string_literal: true

# Example 7: Loan Application
#
# Three levels of conditional branching with composed rules (all, any).
#
# Level 1: Loan type (Personal / Mortgage / Business) splits into different paths.
# Level 2: Within Mortgage, property type triggers sub-branches.
#          Within Business, revenue level triggers sub-branches.
# Level 3: High-value mortgage applicants with specific conditions get
#          additional scrutiny. Low-revenue startups get a different path
#          than established businesses.
#
# Demonstrates: all(), any(), greater_than, less_than, equals, contains,
#               three-level deep conditional logic, number_matrix.
#
# Run:  bundle exec exe/flowengine-cli run examples/07_loan_application.rb

FlowEngine.define do
  start :applicant_info

  step :applicant_info do
    type :text
    question "Full legal name:"
    transition to: :loan_type
  end

  step :loan_type do
    type :single_select
    question "What type of loan are you applying for?"
    options %w[Personal Mortgage Business]
    transition to: :personal_amount, if_rule: equals(:loan_type, "Personal")
    transition to: :mortgage_property, if_rule: equals(:loan_type, "Mortgage")
    transition to: :business_info, if_rule: equals(:loan_type, "Business")
  end

  # ============================================================
  # LEVEL 1 — Personal loan (simple path)
  # ============================================================

  step :personal_amount do
    type :number
    question "How much would you like to borrow (in dollars)?"
    transition to: :personal_purpose
  end

  step :personal_purpose do
    type :single_select
    question "What is the primary purpose of this loan?"
    options %w[DebtConsolidation HomeImprovement Medical Travel Education Other]
    transition to: :credit_check
  end

  # ============================================================
  # LEVEL 1 — Mortgage branch
  # ============================================================

  step :mortgage_property do
    type :single_select
    question "What type of property is this for?"
    options %w[SingleFamily Condo Townhouse MultiFamily Commercial]
    transition to: :mortgage_amount
  end

  step :mortgage_amount do
    type :number
    question "What is the estimated property value (in dollars)?"
    transition to: :mortgage_high_value, if_rule: greater_than(:mortgage_amount, 750_000)
    transition to: :down_payment
  end

  # LEVEL 2 — High-value mortgage
  step :mortgage_high_value do
    type :boolean
    question "Will this be your primary residence?"
    transition to: :jumbo_review, if_rule: all(
      equals(:mortgage_high_value, false),
      greater_than(:mortgage_amount, 750_000)
    )
    transition to: :down_payment
  end

  # LEVEL 3 — Investment property jumbo loan
  step :jumbo_review do
    type :number_matrix
    question "Provide details about your existing properties:"
    fields %w[OwnedProperties RentalProperties MortgagesOwed]
    transition to: :down_payment
  end

  step :down_payment do
    type :number
    question "How much is your down payment (in dollars)?"
    transition to: :credit_check
  end

  # ============================================================
  # LEVEL 1 — Business loan branch
  # ============================================================

  step :business_info do
    type :text
    question "Business name and EIN:"
    transition to: :business_type
  end

  step :business_type do
    type :single_select
    question "Business structure:"
    options %w[SoleProprietor LLC SCorp CCorp Partnership]
    transition to: :annual_revenue
  end

  step :annual_revenue do
    type :number
    question "What is your annual revenue (in dollars)?"
    transition to: :startup_details, if_rule: less_than(:annual_revenue, 100_000)
    transition to: :established_details, if_rule: greater_than(:annual_revenue, 500_000)
    transition to: :business_loan_amount
  end

  # LEVEL 2 — Startup path
  step :startup_details do
    type :number
    question "How many months has the business been operating?"
    transition to: :startup_funding, if_rule: less_than(:startup_details, 12)
    transition to: :business_loan_amount
  end

  # LEVEL 3 — Very new startup
  step :startup_funding do
    type :multi_select
    question "What funding sources have you used so far?"
    options %w[PersonalSavings FriendsFamily AngelInvestor VentureCapital Grant CreditCards None]
    transition to: :business_loan_amount
  end

  # LEVEL 2 — Established business path
  step :established_details do
    type :number_matrix
    question "Provide financial details:"
    fields %w[Employees AnnualExpenses OutstandingDebt]
    transition to: :established_expansion, if_rule: all(
      greater_than(:annual_revenue, 500_000),
      any(
        equals(:business_type, "CCorp"),
        equals(:business_type, "SCorp")
      )
    )
    transition to: :business_loan_amount
  end

  # LEVEL 3 — Corp expansion review
  step :established_expansion do
    type :multi_select
    question "What will the loan fund?"
    options %w[Hiring Equipment RealEstate Acquisition Marketing RAndD]
    transition to: :business_loan_amount
  end

  step :business_loan_amount do
    type :number
    question "How much funding are you requesting (in dollars)?"
    transition to: :credit_check
  end

  # ============================================================
  # Common tail
  # ============================================================

  step :credit_check do
    type :boolean
    question "Do you authorize a credit check?"
    transition to: :review, if_rule: equals(:credit_check, true)
    transition to: :declined
  end

  step :declined do
    type :display
    question "A credit check is required to proceed. Your application has been saved as a draft."
  end

  step :review do
    type :display
    question "Application submitted! You will receive a decision within 3-5 business days."
  end
end
