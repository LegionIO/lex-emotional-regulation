# frozen_string_literal: true

RSpec.describe Legion::Extensions::EmotionalRegulation::Helpers::RegulationModel do
  subject(:model) { described_class.new }

  let(:c) { Legion::Extensions::EmotionalRegulation::Helpers::Constants }

  describe '#initialize' do
    it 'starts all skills at DEFAULT_SKILL' do
      c::STRATEGIES.each do |strategy|
        expect(model.skill[strategy]).to eq(c::DEFAULT_SKILL)
      end
    end

    it 'starts with zero consecutive suppressions' do
      expect(model.consecutive_suppressions).to eq(0)
    end

    it 'starts with empty history' do
      expect(model.regulation_history).to be_empty
    end
  end

  describe '#regulate' do
    context 'with a valid strategy' do
      it 'returns success: true' do
        result = model.regulate(emotion_magnitude: 0.8, emotion_valence: :negative, strategy: :cognitive_reappraisal)
        expect(result[:success]).to be(true)
      end

      it 'reduces emotion magnitude' do
        result = model.regulate(emotion_magnitude: 0.8, emotion_valence: :negative, strategy: :cognitive_reappraisal)
        expect(result[:regulated_magnitude]).to be < 0.8
      end

      it 'returns the strategy used' do
        result = model.regulate(emotion_magnitude: 0.5, emotion_valence: :neutral, strategy: :attentional_deployment)
        expect(result[:strategy]).to eq(:attentional_deployment)
      end

      it 'returns a cost value' do
        result = model.regulate(emotion_magnitude: 0.6, emotion_valence: :neutral, strategy: :situation_modification)
        expect(result[:cost]).to be > 0.0
      end

      it 'records an event in history' do
        expect { model.regulate(emotion_magnitude: 0.5, emotion_valence: :neutral, strategy: :cognitive_reappraisal) }
          .to change { model.regulation_history.size }.by(1)
      end

      it 'does not reduce regulated_magnitude below 0' do
        result = model.regulate(emotion_magnitude: 0.0, emotion_valence: :neutral, strategy: :situation_selection)
        expect(result[:regulated_magnitude]).to be >= 0.0
      end
    end

    context 'with an unknown strategy' do
      it 'returns success: false' do
        result = model.regulate(emotion_magnitude: 0.5, emotion_valence: :neutral, strategy: :teleportation)
        expect(result[:success]).to be(false)
      end

      it 'does not change the magnitude' do
        result = model.regulate(emotion_magnitude: 0.5, emotion_valence: :neutral, strategy: :teleportation)
        expect(result[:regulated_magnitude]).to eq(0.5)
      end

      it 'includes reason: :unknown_strategy' do
        result = model.regulate(emotion_magnitude: 0.5, emotion_valence: :neutral, strategy: :teleportation)
        expect(result[:reason]).to eq(:unknown_strategy)
      end
    end

    context 'suppression tracking' do
      it 'increments consecutive_suppressions on suppression use' do
        model.regulate(emotion_magnitude: 0.5, emotion_valence: :neutral, strategy: :response_suppression)
        expect(model.consecutive_suppressions).to eq(1)
      end

      it 'resets consecutive_suppressions when a different strategy is used' do
        model.regulate(emotion_magnitude: 0.5, emotion_valence: :neutral, strategy: :response_suppression)
        model.regulate(emotion_magnitude: 0.5, emotion_valence: :neutral, strategy: :cognitive_reappraisal)
        expect(model.consecutive_suppressions).to eq(0)
      end
    end

    context 'skill learning' do
      it 'improves skill on successful regulation' do
        initial = model.skill[:cognitive_reappraisal]
        model.regulate(emotion_magnitude: 0.8, emotion_valence: :negative, strategy: :cognitive_reappraisal)
        expect(model.skill[:cognitive_reappraisal]).to be > initial
      end
    end

    context 'history capping' do
      it 'caps history at MAX_REGULATION_HISTORY' do
        (c::MAX_REGULATION_HISTORY + 10).times do
          model.regulate(emotion_magnitude: 0.5, emotion_valence: :neutral, strategy: :attentional_deployment)
        end
        expect(model.regulation_history.size).to eq(c::MAX_REGULATION_HISTORY)
      end
    end
  end

  describe '#recommend_strategy' do
    it 'returns a recommended strategy' do
      result = model.recommend_strategy(emotion_magnitude: 0.7, emotion_valence: :negative)
      expect(c::STRATEGIES).to include(result[:recommended])
    end

    it 'returns scores for all strategies' do
      result = model.recommend_strategy(emotion_magnitude: 0.5, emotion_valence: :neutral)
      expect(result[:scores].keys).to match_array(c::STRATEGIES)
    end

    it 'returns the context' do
      result = model.recommend_strategy(emotion_magnitude: 0.5, emotion_valence: :neutral, context: :sustained)
      expect(result[:context]).to eq(:sustained)
    end

    it 'penalises situation_selection at high magnitude' do
      result = model.recommend_strategy(emotion_magnitude: 0.9, emotion_valence: :negative, context: :general)
      # situation_selection should score lower than cognitive_reappraisal at high magnitude
      expect(result[:scores][:situation_selection]).to be < result[:scores][:cognitive_reappraisal]
    end

    it 'penalises suppression in sustained context' do
      general_result = model.recommend_strategy(emotion_magnitude: 0.5, emotion_valence: :neutral, context: :general)
      sustained_result = model.recommend_strategy(emotion_magnitude: 0.5, emotion_valence: :neutral, context: :sustained)
      expect(sustained_result[:scores][:response_suppression]).to be < general_result[:scores][:response_suppression]
    end
  end

  describe '#decay' do
    it 'moves skills above DEFAULT_SKILL toward DEFAULT_SKILL' do
      model.instance_variable_get(:@skill)[:cognitive_reappraisal] = 0.8
      model.decay
      expect(model.skill[:cognitive_reappraisal]).to be < 0.8
    end

    it 'does not decay skills below 0' do
      c::STRATEGIES.each do |s|
        model.instance_variable_get(:@skill)[s] = 0.0
      end
      model.decay
      c::STRATEGIES.each do |s|
        expect(model.skill[s]).to be >= 0.0
      end
    end
  end

  describe '#skill_for' do
    it 'returns the skill value for a known strategy' do
      expect(model.skill_for(:cognitive_reappraisal)).to eq(c::DEFAULT_SKILL)
    end

    it 'returns DEFAULT_SKILL for an unknown strategy' do
      expect(model.skill_for(:nonexistent)).to eq(c::DEFAULT_SKILL)
    end
  end

  describe '#overall_regulation_ability' do
    it 'returns a float in [0, 1]' do
      ability = model.overall_regulation_ability
      expect(ability).to be_between(0.0, 1.0)
    end

    it 'starts at DEFAULT_SKILL when all skills are equal' do
      expect(model.overall_regulation_ability).to be_within(0.001).of(c::DEFAULT_SKILL)
    end
  end

  describe '#regulation_label' do
    it 'returns a symbol from REGULATION_LABELS' do
      expect(c::REGULATION_LABELS.values).to include(model.regulation_label)
    end

    it 'returns :novice when ability is around DEFAULT_SKILL (0.3)' do
      expect(model.regulation_label).to eq(:novice)
    end

    it 'returns :masterful when all skills are near 1.0' do
      c::STRATEGIES.each do |s|
        model.instance_variable_get(:@skill)[s] = 0.95
      end
      expect(model.regulation_label).to eq(:masterful)
    end
  end

  describe '#to_h' do
    it 'includes all expected keys' do
      hash = model.to_h
      expect(hash.keys).to include(:skill, :consecutive_suppressions, :overall_ability, :regulation_label, :history_size)
    end

    it 'returns a duplicate of skill (not same object)' do
      expect(model.to_h[:skill]).not_to be(model.skill)
    end
  end
end
