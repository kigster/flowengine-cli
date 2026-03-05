# frozen_string_literal: true

# Example 6: Health Risk Assessment
#
# Three levels of conditional branching with composed rules.
#
# Level 1: Lifestyle choices branch into exercise, smoking, or diet paths.
# Level 2: Within exercise, intensity level opens a sub-branch.
#          Within smoking, pack count opens a sub-branch.
# Level 3: Heavy smokers with additional risk factors get a deeper follow-up.
#
# Demonstrates: all(), any(), greater_than, less_than, contains, equals,
#               three-level deep conditional logic.
#
# Run:  bundle exec exe/flowengine-cli run examples/06_health_assessment.rb

FlowEngine.define do
  start :patient_info

  step :patient_info do
    type :text
    question "Patient name and date of birth (e.g., Jane Doe, 1985-03-15):"
    transition to: :lifestyle
  end

  step :lifestyle do
    type :multi_select
    question "Select all that apply to your lifestyle:"
    options %w[Exercise Smoking Alcohol HighStress PoorDiet]
    transition to: :exercise_frequency, if_rule: contains(:lifestyle, "Exercise")
    transition to: :smoking_details, if_rule: contains(:lifestyle, "Smoking")
    transition to: :diet_details, if_rule: contains(:lifestyle, "PoorDiet")
    transition to: :sleep_quality
  end

  # ============================================================
  # LEVEL 1 — Exercise branch
  # ============================================================

  step :exercise_frequency do
    type :number
    question "How many days per week do you exercise?"
    transition to: :exercise_intensity, if_rule: greater_than(:exercise_frequency, 3)
    transition to: :smoking_details, if_rule: contains(:lifestyle, "Smoking")
    transition to: :diet_details, if_rule: contains(:lifestyle, "PoorDiet")
    transition to: :sleep_quality
  end

  # LEVEL 2 — Intense exerciser sub-branch
  step :exercise_intensity do
    type :single_select
    question "What best describes your typical workout intensity?"
    options %w[Moderate Vigorous Extreme]
    transition to: :injury_history, if_rule: equals(:exercise_intensity, "Extreme")
    transition to: :smoking_details, if_rule: contains(:lifestyle, "Smoking")
    transition to: :diet_details, if_rule: contains(:lifestyle, "PoorDiet")
    transition to: :sleep_quality
  end

  # LEVEL 3 — Extreme exerciser injury check
  step :injury_history do
    type :boolean
    question "Have you had any exercise-related injuries in the past year?"
    transition to: :smoking_details, if_rule: contains(:lifestyle, "Smoking")
    transition to: :diet_details, if_rule: contains(:lifestyle, "PoorDiet")
    transition to: :sleep_quality
  end

  # ============================================================
  # LEVEL 1 — Smoking branch
  # ============================================================

  step :smoking_details do
    type :number
    question "How many packs per day do you smoke?"
    transition to: :smoking_duration, if_rule: greater_than(:smoking_details, 1)
    transition to: :diet_details, if_rule: contains(:lifestyle, "PoorDiet")
    transition to: :sleep_quality
  end

  # LEVEL 2 — Heavy smoker sub-branch
  step :smoking_duration do
    type :number
    question "How many years have you been smoking?"
    transition to: :smoking_cessation, if_rule: all(
      greater_than(:smoking_duration, 10),
      greater_than(:smoking_details, 1)
    )
    transition to: :diet_details, if_rule: contains(:lifestyle, "PoorDiet")
    transition to: :sleep_quality
  end

  # LEVEL 3 — Long-term heavy smoker: cessation counseling
  step :smoking_cessation do
    type :boolean
    question "Have you tried a cessation program before?"
    transition to: :cessation_details, if_rule: equals(:smoking_cessation, true)
    transition to: :diet_details, if_rule: contains(:lifestyle, "PoorDiet")
    transition to: :sleep_quality
  end

  step :cessation_details do
    type :text
    question "Please describe what programs you tried and when:"
    transition to: :diet_details, if_rule: contains(:lifestyle, "PoorDiet")
    transition to: :sleep_quality
  end

  # ============================================================
  # LEVEL 1 — Diet branch
  # ============================================================

  step :diet_details do
    type :multi_select
    question "Which of these describe your typical diet?"
    options %w[HighSugar HighSodium LowFiber SkipsMeals FastFood ProcessedFoods]
    transition to: :sleep_quality
  end

  # ============================================================
  # Common tail
  # ============================================================

  step :sleep_quality do
    type :single_select
    question "How would you rate your sleep quality?"
    options %w[Excellent Good Fair Poor]
    transition to: :mental_health, if_rule: any(
      equals(:sleep_quality, "Fair"),
      equals(:sleep_quality, "Poor")
    )
    transition to: :family_history
  end

  step :mental_health do
    type :multi_select
    question "Do any of these apply to you?"
    options %w[Anxiety Depression Insomnia ChronicFatigue None]
    transition to: :family_history
  end

  step :family_history do
    type :multi_select
    question "Select any conditions that run in your family:"
    options %w[HeartDisease Diabetes Cancer Hypertension None]
    transition to: :risk_summary
  end

  step :risk_summary do
    type :display
    question "Assessment complete. Your responses have been recorded for review by your provider."
  end
end
