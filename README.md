# lex-emotional-regulation

Emotional regulation modeling for the LegionIO brain-modeled cognitive architecture.

## What It Does

Implements Gross's process model of emotion regulation — the cognitive strategies an agent uses to modify its emotional responses. When raw emotional valence or arousal is extreme, the agent can apply one of five regulation strategies to bring its internal state back to a workable range. Tracks regulatory effort (which depletes and recovers), effectiveness per strategy, and rebound risk from suppression.

## Usage

```ruby
client = Legion::Extensions::EmotionalRegulation::Client.new

# Apply a regulation strategy to a raw emotional state
client.regulate_emotion(valence: -0.9, arousal: 0.8, strategy: :reappraisal)
# => { success: true, strategy: :reappraisal, regulated_valence: -0.6,
#      regulated_arousal: 0.8, effort_cost: 0.1, effectiveness: 0.7 }

# Use specific strategies directly
client.apply_suppression(valence: -0.7, arousal: 0.9)
# => { success: true, regulated_valence: -0.7, regulated_arousal: 0.5, rebound_risk: true }

client.apply_distancing(valence: -0.8, arousal: 0.7)
# => { success: true, regulated_valence: -0.4, regulated_arousal: 0.35 }

client.apply_savoring(valence: 0.6)
# => { success: true, regulated_valence: 0.9, shift: 0.3 }

client.apply_acceptance(valence: -0.5, arousal: 0.4)
# => { success: true, regulated_valence: -0.5, regulated_arousal: 0.3 }

# Check regulatory capacity
client.regulation_status
# => { effort_budget: 0.7, effort_label: :effortful, recent_strategies: [:reappraisal, :distancing], effectiveness_avg: 0.65 }

# Check which strategy works best
client.strategy_effectiveness(strategy: :reappraisal)
# => { strategy: :reappraisal, uses: 12, avg_effectiveness: 0.72, best_for: :negative_valence }

# Periodic maintenance: recover effort
client.update_emotional_regulation
```

## Regulation Strategies

| Strategy | Effect | Notes |
|---|---|---|
| `:reappraisal` | Shifts valence toward neutral | Most effective, higher effort |
| `:suppression` | Reduces arousal | Low effectiveness; carries rebound risk |
| `:distancing` | Moves both toward neutral | Moderate effectiveness |
| `:acceptance` | Reduces arousal slightly | Lowest effort; leaves valence intact |
| `:savoring` | Amplifies positive valence | Only applies to positive states |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
