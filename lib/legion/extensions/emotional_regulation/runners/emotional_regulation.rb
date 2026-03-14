# frozen_string_literal: true

module Legion
  module Extensions
    module EmotionalRegulation
      module Runners
        module EmotionalRegulation
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          # Apply emotion regulation. Auto-selects strategy when none is provided.
          def regulate_emotion(emotion_magnitude:, emotion_valence: :neutral, strategy: nil, **)
            chosen = strategy || regulation_model.recommend_strategy(
              emotion_magnitude: emotion_magnitude,
              emotion_valence:   emotion_valence
            )[:recommended]

            result = regulation_model.regulate(
              emotion_magnitude: emotion_magnitude,
              emotion_valence:   emotion_valence,
              strategy:          chosen
            )

            Legion::Logging.debug "[emotional_regulation] regulate: strategy=#{chosen} " \
                                  "magnitude=#{emotion_magnitude.round(2)} -> " \
                                  "#{result[:regulated_magnitude].round(2)} " \
                                  "cost=#{result[:cost].round(3)} success=#{result[:success]}"

            { success: true }.merge(result)
          end

          # Return a strategy recommendation without applying it.
          def recommend_strategy(emotion_magnitude:, emotion_valence: :neutral, context: :general, **)
            result = regulation_model.recommend_strategy(
              emotion_magnitude: emotion_magnitude,
              emotion_valence:   emotion_valence,
              context:           context
            )

            Legion::Logging.debug "[emotional_regulation] recommend: magnitude=#{emotion_magnitude.round(2)} " \
                                  "context=#{context} recommended=#{result[:recommended]}"

            { success: true }.merge(result)
          end

          # Per-tick skill decay — call from scheduler or tick actor.
          def update_emotional_regulation(**)
            regulation_model.decay
            ability = regulation_model.overall_regulation_ability
            label   = regulation_model.regulation_label

            Legion::Logging.debug "[emotional_regulation] decay tick: ability=#{ability.round(3)} label=#{label}"

            { success: true, overall_ability: ability, regulation_label: label }
          end

          # Return the full skill profile across all strategies.
          def regulation_profile(**)
            profile = Helpers::Constants::STRATEGIES.to_h do |strategy|
              [strategy, regulation_model.skill_for(strategy)]
            end

            Legion::Logging.debug "[emotional_regulation] profile query: overall=#{regulation_model.overall_regulation_ability.round(3)}"

            {
              success:      true,
              skills:       profile,
              overall:      regulation_model.overall_regulation_ability,
              label:        regulation_model.regulation_label,
              suppressions: regulation_model.consecutive_suppressions
            }
          end

          # Return recent regulation events.
          def regulation_history(count: 20, **)
            events = regulation_model.regulation_history.last(count)
            Legion::Logging.debug "[emotional_regulation] history: requested=#{count} returned=#{events.size}"
            { success: true, events: events, count: events.size }
          end

          # Return aggregate statistics about regulation performance.
          def emotional_regulation_stats(**)
            history = regulation_model.regulation_history
            total   = history.size

            if total.zero?
              return { success: true, total_events: 0, success_rate: 0.0,
                       average_cost: 0.0, strategy_breakdown: {},
                       overall_ability: regulation_model.overall_regulation_ability,
                       regulation_label: regulation_model.regulation_label }
            end

            successes  = history.count { |e| e[:success] }
            total_cost = history.sum { |e| e[:cost] }

            strategy_breakdown = Helpers::Constants::STRATEGIES.to_h do |strategy|
              events = history.select { |e| e[:strategy] == strategy }
              [strategy, { count: events.size, successes: events.count { |e| e[:success] } }]
            end

            Legion::Logging.debug "[emotional_regulation] stats: total=#{total} success_rate=#{(successes.to_f / total).round(2)}"

            {
              success:            true,
              total_events:       total,
              success_rate:       successes.to_f / total,
              average_cost:       total_cost / total,
              strategy_breakdown: strategy_breakdown,
              overall_ability:    regulation_model.overall_regulation_ability,
              regulation_label:   regulation_model.regulation_label
            }
          end

          private

          def regulation_model
            @regulation_model ||= Helpers::RegulationModel.new
          end
        end
      end
    end
  end
end
