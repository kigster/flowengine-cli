# frozen_string_literal: true

# Example 5: Job Application Intake
#
# Two levels of branching with composed rules (all/any).
# The role determines the first branch; experience level and
# specific answers open deeper sub-branches.
# Demonstrates: all(), any(), greater_than, contains, two-level branching.
#
# Run:  bundle exec exe/flowengine-cli run examples/05_job_application.rb

FlowEngine.define do
  start :applicant_name

  step :applicant_name do
    type :text
    question "What is your full name?"
    transition to: :role
  end

  step :role do
    type :single_select
    question "Which role are you applying for?"
    options %w[Engineering Design ProductManagement Sales]
    transition to: :engineering_skills, if_rule: equals(:role, "Engineering")
    transition to: :design_portfolio, if_rule: equals(:role, "Design")
    transition to: :years_experience
  end

  # --- Engineering branch (level 1) ---

  step :engineering_skills do
    type :multi_select
    question "Select your primary skills:"
    options %w[Ruby Python JavaScript Go Rust Java]
    transition to: :years_experience
  end

  # --- Design branch (level 1) ---

  step :design_portfolio do
    type :text
    question "Please provide a link to your portfolio:"
    transition to: :years_experience
  end

  # --- Common: experience (feeds level 2 branching) ---

  step :years_experience do
    type :number
    question "How many years of professional experience do you have?"
    transition to: :leadership_experience, if_rule: greater_than(:years_experience, 7)
    transition to: :education
  end

  # Level 2 branch: senior applicants
  step :leadership_experience do
    type :boolean
    question "Have you managed a team of 5 or more people?"
    transition to: :management_style, if_rule: equals(:leadership_experience, true)
    transition to: :education
  end

  # Level 2 sub-branch: managers
  step :management_style do
    type :single_select
    question "How would you describe your management style?"
    options %w[Collaborative Directive Coaching Delegative]
    transition to: :education
  end

  step :education do
    type :single_select
    question "What is your highest level of education?"
    options %w[HighSchool Bachelors Masters PhD Bootcamp SelfTaught]
    transition to: :availability
  end

  step :availability do
    type :single_select
    question "When can you start?"
    options %w[Immediately TwoWeeks OneMonth ThreeMonths]
    transition to: :referral
  end

  step :referral do
    type :boolean
    question "Were you referred by a current employee?"
    transition to: :referral_name, if_rule: equals(:referral, true)
    transition to: :thanks
  end

  step :referral_name do
    type :text
    question "Who referred you?"
    transition to: :thanks
  end

  step :thanks do
    type :display
    question "Application submitted! We'll be in touch within 5 business days."
  end
end
