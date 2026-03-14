# frozen_string_literal: true

module Legion
  module Extensions
    module EmotionalRegulation
      module Helpers
        class RegulationModel
          include Constants

          attr_reader :skill, :consecutive_suppressions, :regulation_history

          def initialize
            @skill = STRATEGIES.to_h { |s| [s, DEFAULT_SKILL] }
            @consecutive_suppressions = 0
            @regulation_history = []
          end

          # Apply a regulation strategy to an emotion.
          #
          # Returns a hash with :regulated_magnitude, :cost, :success
          def regulate(emotion_magnitude:, emotion_valence:, strategy:)
            unless STRATEGIES.include?(strategy)
              return { regulated_magnitude: emotion_magnitude, cost: 0.0, success: false,
                       reason: :unknown_strategy }
            end

            base_effectiveness = STRATEGY_EFFECTIVENESS[strategy]
            base_cost          = STRATEGY_COST[strategy]
            proficiency        = @skill[strategy]

            # Proficiency scales effectiveness (skill of 1.0 adds 20% to base)
            effective_reduction = base_effectiveness * (1.0 + (proficiency * 0.2))
            effective_reduction = [effective_reduction, 1.0].min

            # Suppression penalty: repeated suppression degrades its own effectiveness
            effective_reduction = apply_suppression_penalty(strategy, effective_reduction)

            regulated = (emotion_magnitude * (1.0 - effective_reduction)).clamp(0.0, 1.0)
            actual_cost = base_cost * (1.0 - (proficiency * 0.3))

            success = regulated < emotion_magnitude
            update_skill(strategy, success: success)
            track_suppression(strategy)
            record_event({
                           strategy:            strategy,
                           emotion_magnitude:   emotion_magnitude,
                           regulated_magnitude: regulated,
                           cost:                actual_cost,
                           emotion_valence:     emotion_valence,
                           success:             success
                         })

            { regulated_magnitude: regulated, cost: actual_cost, success: success,
              strategy: strategy, proficiency: proficiency }
          end

          # Recommend the best strategy given current skills and context.
          def recommend_strategy(emotion_magnitude:, emotion_valence:, context: :general)
            scores = STRATEGIES.to_h do |strategy|
              [strategy, score_strategy(strategy, emotion_magnitude, emotion_valence, context)]
            end

            best = scores.max_by { |_, v| v }[0]
            { recommended: best, scores: scores, context: context }
          end

          # Decay all skills toward DEFAULT_SKILL by SKILL_DECAY each tick.
          def decay
            @skill.each_key do |strategy|
              current = @skill[strategy]
              @skill[strategy] = if current > DEFAULT_SKILL
                                   [current - SKILL_DECAY, DEFAULT_SKILL].max
                                 else
                                   [current + (SKILL_DECAY * 0.5), DEFAULT_SKILL].min
                                 end
            end
          end

          # Get proficiency for a specific strategy.
          def skill_for(strategy)
            @skill.fetch(strategy, DEFAULT_SKILL)
          end

          # Weighted average of all strategy skills.
          # Effectiveness-weighted so higher-value strategies contribute more.
          def overall_regulation_ability
            total_weight = STRATEGIES.sum { |s| STRATEGY_EFFECTIVENESS[s] }
            weighted_sum = STRATEGIES.sum { |s| @skill[s] * STRATEGY_EFFECTIVENESS[s] }
            weighted_sum / total_weight
          end

          # Human-readable label for overall regulation ability.
          def regulation_label
            ability = overall_regulation_ability
            REGULATION_LABELS.each do |range, label|
              return label if range.cover?(ability)
            end
            :reactive
          end

          def to_h
            {
              skill:                    @skill.dup,
              consecutive_suppressions: @consecutive_suppressions,
              overall_ability:          overall_regulation_ability,
              regulation_label:         regulation_label,
              history_size:             @regulation_history.size
            }
          end

          private

          def score_strategy(strategy, emotion_magnitude, _emotion_valence, context)
            effectiveness = STRATEGY_EFFECTIVENESS[strategy]
            cost          = STRATEGY_COST[strategy]
            proficiency   = @skill[strategy]

            base_score = (effectiveness * 0.5) + (proficiency * 0.3) - (cost * 0.2)

            # Reappraisal bonus — healthiest long-term strategy
            base_score += REAPPRAISAL_BONUS if strategy == :cognitive_reappraisal

            # In high-magnitude situations penalise situation_selection (too late to avoid)
            base_score -= 0.15 if strategy == :situation_selection && emotion_magnitude > 0.7

            # Suppression penalty in long-running contexts
            if strategy == :response_suppression
              base_score -= 0.1 if context == :sustained
              base_score -= ([@consecutive_suppressions, SUPPRESSION_PENALTY_THRESHOLD].min * 0.03)
            end

            base_score
          end

          def apply_suppression_penalty(strategy, effectiveness)
            return effectiveness unless strategy == :response_suppression
            return effectiveness if @consecutive_suppressions < SUPPRESSION_PENALTY_THRESHOLD

            excess = @consecutive_suppressions - SUPPRESSION_PENALTY_THRESHOLD
            penalty = [excess * 0.05, 0.2].min
            [effectiveness - penalty, 0.05].max
          end

          def update_skill(strategy, success:)
            current = @skill[strategy]
            if success
              bonus = strategy == :cognitive_reappraisal ? SKILL_GAIN * 1.2 : SKILL_GAIN
              @skill[strategy] = [current + bonus, 1.0].min
            else
              @skill[strategy] = [current - (SKILL_GAIN * 0.5), 0.0].max
            end
          end

          def track_suppression(strategy)
            if strategy == :response_suppression
              @consecutive_suppressions += 1
            else
              @consecutive_suppressions = 0
            end
          end

          def record_event(data)
            event = data.merge(timestamp: Time.now.utc)
            @regulation_history << event
            @regulation_history.shift while @regulation_history.size > MAX_REGULATION_HISTORY
          end
        end
      end
    end
  end
end
