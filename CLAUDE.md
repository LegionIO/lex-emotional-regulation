# lex-emotional-regulation

**Level 3 Documentation** — Parent: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`

## Purpose

Emotional regulation modeling for the LegionIO cognitive architecture. Implements Gross's process model of emotion regulation — the cognitive mechanisms by which an agent modifies its emotional responses. Supports five regulation strategies: reappraisal (reinterpreting meaning), suppression (inhibiting expression), distancing (psychological detachment), acceptance (allowing without resistance), and savoring (amplifying positive states). Tracks regulation effort and effectiveness.

## Gem Info

- **Gem name**: `lex-emotional-regulation`
- **Version**: `0.1.0`
- **Namespace**: `Legion::Extensions::EmotionalRegulation`
- **Location**: `extensions-agentic/lex-emotional-regulation/`

## File Structure

```
lib/legion/extensions/emotional_regulation/
  emotional_regulation.rb       # Top-level requires
  version.rb                    # VERSION = '0.1.0'
  client.rb                     # Client class
  helpers/
    constants.rb                # REGULATION_STRATEGIES, EFFECTIVENESS_RATES, EFFORT_COSTS, labels
    regulation_event.rb         # RegulationEvent value object
    regulation_engine.rb        # Engine: strategy application, effectiveness tracking
  runners/
    emotional_regulation.rb     # Runner module: all public methods
```

## Key Constants

| Constant | Value | Purpose |
|---|---|---|
| `REGULATION_STRATEGIES` | `[:reappraisal, :suppression, :distancing, :acceptance, :savoring]` | Valid strategies |
| `EFFECTIVENESS_RATES` | hash per strategy | Valence change magnitude per strategy application |
| `EFFORT_COSTS` | hash per strategy | Regulatory effort consumed per strategy use |
| `REGULATION_DECAY` | 0.02 | Effect decay per cycle |
| `EFFORT_RECOVERY_RATE` | 0.05 | Regulatory effort recovered per update cycle |
| `MAX_REGULATION_EVENTS` | 200 | Rolling event log cap |
| `REGULATION_FLOOR` | -1.0 | Minimum regulated valence |
| `REGULATION_CEILING` | 1.0 | Maximum regulated valence |
| `EFFECTIVENESS_LABELS` | range hash | `highly_effective / effective / moderate / low / ineffective` |
| `STRATEGY_LABELS` | hash | Human-readable description per strategy |

## Runners

All methods in `Legion::Extensions::EmotionalRegulation::Runners::EmotionalRegulation`.

| Method | Key Args | Returns |
|---|---|---|
| `regulate_emotion` | `valence:, arousal:, strategy:, context: {}` | `{ success:, strategy:, regulated_valence:, regulated_arousal:, effort_cost:, effectiveness: }` |
| `apply_reappraisal` | `valence:, context: {}` | `{ success:, strategy: :reappraisal, regulated_valence:, shift: }` |
| `apply_suppression` | `valence:, arousal:` | `{ success:, strategy: :suppression, regulated_valence:, regulated_arousal:, rebound_risk: }` |
| `apply_distancing` | `valence:, arousal:` | `{ success:, strategy: :distancing, regulated_valence:, regulated_arousal: }` |
| `apply_acceptance` | `valence:, arousal:` | `{ success:, strategy: :acceptance, regulated_valence:, regulated_arousal: }` |
| `apply_savoring` | `valence:` | `{ success:, strategy: :savoring, regulated_valence:, shift: }` (positive valence only) |
| `regulation_status` | — | `{ success:, effort_budget:, effort_label:, recent_strategies:, effectiveness_avg: }` |
| `strategy_effectiveness` | `strategy: nil` | `{ success:, strategy:, uses:, avg_effectiveness:, best_for: }` |
| `update_emotional_regulation` | — | `{ success:, effort_recovered:, events_decayed: }` |
| `emotional_regulation_stats` | — | Full stats hash including per-strategy breakdown |

## Helpers

### `RegulationEvent`
Value object. Attributes: `id`, `strategy`, `input_valence`, `input_arousal`, `output_valence`, `output_arousal`, `effectiveness`, `effort_cost`, `timestamp`. `to_h`.

### `RegulationEngine`
Central store: `@events` (array, rolling), `@effort_budget` (float 0–1), `@strategy_stats` (hash by strategy). Key methods:
- `apply_strategy(valence:, arousal:, strategy:, context:)`: dispatches to strategy-specific method, deducts effort, logs event, updates `@strategy_stats`
- `reappraise(valence:, context:)`: shifts valence toward neutral by `EFFECTIVENESS_RATES[:reappraisal]`
- `suppress(valence:, arousal:)`: reduces arousal, stores rebound risk flag (suppression temporarily masks without resolving)
- `distance(valence:, arousal:)`: moves both valence and arousal toward neutral
- `accept(valence:, arousal:)`: minimal change — reduces arousal slightly, leaves valence intact
- `savor(valence:)`: amplifies positive valence only; no-op for negative valence
- `recover_effort`: adds `EFFORT_RECOVERY_RATE`, caps at 1.0
- `effectiveness_for(strategy:)`: returns average effectiveness from `@strategy_stats`

## Integration Points

- `regulate_emotion` called from lex-tick's `emotional_evaluation` phase when valence is extreme
- `effort_budget` feeds lex-dual-process's effort model (regulatory exhaustion = less deliberative capacity)
- `rebound_risk` from suppression feeds lex-dissonance as a stress accumulation signal
- `regulation_status[:effectiveness_avg]` informs lex-prediction's confidence for emotional events
- `update_emotional_regulation` maps to lex-tick's periodic maintenance cycle

## Development Notes

- Suppression has a `rebound_risk` side effect: it works short-term but risk of valence rebound is tracked
- Savoring only amplifies positive valence (input_valence > 0); negative input returns unchanged
- Strategy effectiveness is tracked separately from the engine's own EFFECTIVENESS_RATES — actual outcome vs. expected is accumulated in `@strategy_stats`
- Effort budget gates strategy application: when depleted, only acceptance (lowest effort cost) succeeds
- `REGULATION_LABELS` range for effort mirrors lex-dual-process's `ROUTING_LABELS` pattern
