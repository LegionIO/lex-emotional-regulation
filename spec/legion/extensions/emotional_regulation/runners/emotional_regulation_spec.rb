# frozen_string_literal: true

require 'legion/extensions/emotional_regulation/client'

RSpec.describe Legion::Extensions::EmotionalRegulation::Runners::EmotionalRegulation do
  let(:client) { Legion::Extensions::EmotionalRegulation::Client.new }

  describe '#regulate_emotion' do
    it 'returns success: true' do
      result = client.regulate_emotion(emotion_magnitude: 0.7, emotion_valence: :negative)
      expect(result[:success]).to be(true)
    end

    it 'returns a regulated_magnitude' do
      result = client.regulate_emotion(emotion_magnitude: 0.7, emotion_valence: :negative)
      expect(result[:regulated_magnitude]).to be_a(Float)
    end

    it 'reduces magnitude when a valid strategy is provided' do
      result = client.regulate_emotion(emotion_magnitude: 0.8, emotion_valence: :negative,
                                       strategy: :cognitive_reappraisal)
      expect(result[:regulated_magnitude]).to be < 0.8
    end

    it 'auto-selects a strategy when none given' do
      result = client.regulate_emotion(emotion_magnitude: 0.6, emotion_valence: :neutral)
      expect(result[:strategy]).not_to be_nil
    end

    it 'accepts and uses an explicit strategy' do
      result = client.regulate_emotion(emotion_magnitude: 0.5, emotion_valence: :neutral,
                                       strategy: :attentional_deployment)
      expect(result[:strategy]).to eq(:attentional_deployment)
    end

    it 'returns a cost value' do
      result = client.regulate_emotion(emotion_magnitude: 0.5, emotion_valence: :neutral,
                                       strategy: :situation_modification)
      expect(result[:cost]).to be > 0.0
    end

    it 'returns success: false for unknown strategy' do
      result = client.regulate_emotion(emotion_magnitude: 0.5, emotion_valence: :neutral,
                                       strategy: :nonexistent)
      expect(result[:success]).to be(false)
    end
  end

  describe '#recommend_strategy' do
    it 'returns success: true' do
      result = client.recommend_strategy(emotion_magnitude: 0.7, emotion_valence: :negative)
      expect(result[:success]).to be(true)
    end

    it 'returns a recommended strategy symbol' do
      result = client.recommend_strategy(emotion_magnitude: 0.7, emotion_valence: :negative)
      expect(Legion::Extensions::EmotionalRegulation::Helpers::Constants::STRATEGIES).to include(result[:recommended])
    end

    it 'returns scores for all strategies' do
      result = client.recommend_strategy(emotion_magnitude: 0.5, emotion_valence: :neutral)
      expect(result[:scores].keys).to match_array(Legion::Extensions::EmotionalRegulation::Helpers::Constants::STRATEGIES)
    end

    it 'accepts a context parameter' do
      result = client.recommend_strategy(emotion_magnitude: 0.5, emotion_valence: :neutral, context: :sustained)
      expect(result[:context]).to eq(:sustained)
    end
  end

  describe '#update_emotional_regulation' do
    it 'returns success: true' do
      result = client.update_emotional_regulation
      expect(result[:success]).to be(true)
    end

    it 'returns overall_ability' do
      result = client.update_emotional_regulation
      expect(result[:overall_ability]).to be_a(Float)
    end

    it 'returns a regulation_label symbol' do
      result = client.update_emotional_regulation
      expect(result[:regulation_label]).to be_a(Symbol)
    end
  end

  describe '#regulation_profile' do
    it 'returns success: true' do
      result = client.regulation_profile
      expect(result[:success]).to be(true)
    end

    it 'returns skills for all strategies' do
      result = client.regulation_profile
      expect(result[:skills].keys).to match_array(Legion::Extensions::EmotionalRegulation::Helpers::Constants::STRATEGIES)
    end

    it 'returns overall ability' do
      result = client.regulation_profile
      expect(result[:overall]).to be_a(Float)
    end

    it 'returns a label' do
      result = client.regulation_profile
      expect(result[:label]).to be_a(Symbol)
    end

    it 'returns suppressions count' do
      result = client.regulation_profile
      expect(result[:suppressions]).to be_a(Integer)
    end
  end

  describe '#regulation_history' do
    it 'returns success: true' do
      result = client.regulation_history
      expect(result[:success]).to be(true)
    end

    it 'starts with empty events' do
      result = client.regulation_history
      expect(result[:events]).to be_empty
    end

    it 'returns events after regulation' do
      client.regulate_emotion(emotion_magnitude: 0.5, emotion_valence: :neutral, strategy: :cognitive_reappraisal)
      result = client.regulation_history
      expect(result[:count]).to eq(1)
    end

    it 'respects the count parameter' do
      5.times do
        client.regulate_emotion(emotion_magnitude: 0.5, emotion_valence: :neutral, strategy: :attentional_deployment)
      end
      result = client.regulation_history(count: 3)
      expect(result[:events].size).to be <= 3
    end
  end

  describe '#emotional_regulation_stats' do
    it 'returns success: true' do
      result = client.emotional_regulation_stats
      expect(result[:success]).to be(true)
    end

    context 'with no history' do
      it 'returns zero total_events' do
        expect(client.emotional_regulation_stats[:total_events]).to eq(0)
      end

      it 'returns 0.0 success_rate' do
        expect(client.emotional_regulation_stats[:success_rate]).to eq(0.0)
      end
    end

    context 'with some history' do
      before do
        3.times do
          client.regulate_emotion(emotion_magnitude: 0.6, emotion_valence: :negative,
                                  strategy: :cognitive_reappraisal)
        end
      end

      it 'returns correct total_events' do
        expect(client.emotional_regulation_stats[:total_events]).to eq(3)
      end

      it 'returns a success_rate in [0, 1]' do
        rate = client.emotional_regulation_stats[:success_rate]
        expect(rate).to be_between(0.0, 1.0)
      end

      it 'returns average_cost' do
        expect(client.emotional_regulation_stats[:average_cost]).to be > 0.0
      end

      it 'returns a strategy_breakdown hash' do
        breakdown = client.emotional_regulation_stats[:strategy_breakdown]
        expect(breakdown).to be_a(Hash)
        expect(breakdown.keys).to match_array(Legion::Extensions::EmotionalRegulation::Helpers::Constants::STRATEGIES)
      end

      it 'correctly counts strategy usage in breakdown' do
        breakdown = client.emotional_regulation_stats[:strategy_breakdown]
        expect(breakdown[:cognitive_reappraisal][:count]).to eq(3)
      end
    end
  end
end
