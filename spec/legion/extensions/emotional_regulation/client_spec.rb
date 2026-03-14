# frozen_string_literal: true

require 'legion/extensions/emotional_regulation/client'

RSpec.describe Legion::Extensions::EmotionalRegulation::Client do
  subject(:client) { described_class.new }

  describe '#initialize' do
    it 'creates a regulation_model' do
      expect(client.regulation_model).to be_a(Legion::Extensions::EmotionalRegulation::Helpers::RegulationModel)
    end

    it 'accepts an injected regulation_model' do
      custom_model = Legion::Extensions::EmotionalRegulation::Helpers::RegulationModel.new
      c = described_class.new(regulation_model: custom_model)
      expect(c.regulation_model).to be(custom_model)
    end
  end

  it 'responds to all runner methods' do
    expect(client).to respond_to(:regulate_emotion)
    expect(client).to respond_to(:recommend_strategy)
    expect(client).to respond_to(:update_emotional_regulation)
    expect(client).to respond_to(:regulation_profile)
    expect(client).to respond_to(:regulation_history)
    expect(client).to respond_to(:emotional_regulation_stats)
  end

  it 'persists regulation model state across calls' do
    client.regulate_emotion(emotion_magnitude: 0.7, emotion_valence: :negative, strategy: :cognitive_reappraisal)
    stats = client.emotional_regulation_stats
    expect(stats[:total_events]).to eq(1)
  end

  it 'runs a full regulation cycle' do
    # First, get a recommendation
    rec = client.recommend_strategy(emotion_magnitude: 0.8, emotion_valence: :negative)
    expect(rec[:recommended]).to be_a(Symbol)

    # Apply that strategy
    reg = client.regulate_emotion(emotion_magnitude: 0.8, emotion_valence: :negative,
                                  strategy: rec[:recommended])
    expect(reg[:regulated_magnitude]).to be < 0.8

    # Tick decay
    tick = client.update_emotional_regulation
    expect(tick[:success]).to be(true)

    # Check profile
    profile = client.regulation_profile
    expect(profile[:skills]).not_to be_empty

    # Check history
    history = client.regulation_history
    expect(history[:count]).to eq(1)

    # Check stats
    stats = client.emotional_regulation_stats
    expect(stats[:total_events]).to eq(1)
  end
end
