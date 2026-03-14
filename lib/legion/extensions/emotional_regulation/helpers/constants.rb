# frozen_string_literal: true

module Legion
  module Extensions
    module EmotionalRegulation
      module Helpers
        module Constants
          STRATEGIES = %i[
            situation_selection
            situation_modification
            attentional_deployment
            cognitive_reappraisal
            response_suppression
          ].freeze

          # How much each strategy reduces unwanted emotion magnitude (0..1)
          STRATEGY_EFFECTIVENESS = {
            situation_selection:    0.8,
            situation_modification: 0.6,
            attentional_deployment: 0.5,
            cognitive_reappraisal:  0.7,
            response_suppression:   0.3
          }.freeze

          # Cognitive/energetic cost of applying each strategy (0..1)
          STRATEGY_COST = {
            situation_selection:    0.1,
            situation_modification: 0.2,
            attentional_deployment: 0.15,
            cognitive_reappraisal:  0.25,
            response_suppression:   0.35
          }.freeze

          # EMA alpha for skill updating
          REGULATION_ALPHA = 0.12

          # Initial per-strategy proficiency
          DEFAULT_SKILL = 0.3

          # Improvement per successful regulated use
          SKILL_GAIN = 0.05

          # Per-tick decay toward DEFAULT_SKILL
          SKILL_DECAY = 0.01

          # Maximum regulation events retained in history
          MAX_REGULATION_HISTORY = 200

          # Consecutive suppression uses before a penalty applies
          SUPPRESSION_PENALTY_THRESHOLD = 5

          # Bonus applied to recommendation score when reappraisal is chosen
          REAPPRAISAL_BONUS = 0.1

          # Human-readable proficiency labels keyed by magnitude ranges
          REGULATION_LABELS = {
            (0.8..)     => :masterful,
            (0.6...0.8) => :proficient,
            (0.4...0.6) => :developing,
            (0.2...0.4) => :novice,
            (..0.2)     => :reactive
          }.freeze
        end
      end
    end
  end
end
