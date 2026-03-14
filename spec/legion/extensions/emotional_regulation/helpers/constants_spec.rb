# frozen_string_literal: true

RSpec.describe Legion::Extensions::EmotionalRegulation::Helpers::Constants do
  let(:mod) { described_class }

  describe 'STRATEGIES' do
    it 'defines all five strategies' do
      expect(mod::STRATEGIES).to eq(%i[
                                      situation_selection
                                      situation_modification
                                      attentional_deployment
                                      cognitive_reappraisal
                                      response_suppression
                                    ])
    end

    it 'is frozen' do
      expect(mod::STRATEGIES).to be_frozen
    end
  end

  describe 'STRATEGY_EFFECTIVENESS' do
    it 'covers all strategies' do
      expect(mod::STRATEGY_EFFECTIVENESS.keys).to match_array(mod::STRATEGIES)
    end

    it 'has values in [0, 1]' do
      mod::STRATEGY_EFFECTIVENESS.each_value do |v|
        expect(v).to be_between(0.0, 1.0)
      end
    end

    it 'ranks situation_selection as most effective' do
      expect(mod::STRATEGY_EFFECTIVENESS[:situation_selection]).to eq(0.8)
    end

    it 'ranks response_suppression as least effective' do
      expect(mod::STRATEGY_EFFECTIVENESS[:response_suppression]).to eq(0.3)
    end
  end

  describe 'STRATEGY_COST' do
    it 'covers all strategies' do
      expect(mod::STRATEGY_COST.keys).to match_array(mod::STRATEGIES)
    end

    it 'has values in [0, 1]' do
      mod::STRATEGY_COST.each_value do |v|
        expect(v).to be_between(0.0, 1.0)
      end
    end

    it 'ranks situation_selection as lowest cost' do
      expect(mod::STRATEGY_COST[:situation_selection]).to eq(0.1)
    end

    it 'ranks response_suppression as highest cost' do
      expect(mod::STRATEGY_COST[:response_suppression]).to eq(0.35)
    end
  end

  describe 'REGULATION_LABELS' do
    it 'covers all ranges without gaps for values 0..1' do
      [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0].each do |value|
        matched = mod::REGULATION_LABELS.any? { |range, _| range.cover?(value) }
        expect(matched).to be(true), "No range covers #{value}"
      end
    end

    it 'maps 1.0 to :masterful' do
      label = mod::REGULATION_LABELS.find { |range, _| range.cover?(1.0) }&.last
      expect(label).to eq(:masterful)
    end

    it 'maps 0.0 to :reactive' do
      label = mod::REGULATION_LABELS.find { |range, _| range.cover?(0.0) }&.last
      expect(label).to eq(:reactive)
    end

    it 'maps 0.5 to :developing' do
      label = mod::REGULATION_LABELS.find { |range, _| range.cover?(0.5) }&.last
      expect(label).to eq(:developing)
    end
  end

  describe 'numeric constants' do
    it 'has REGULATION_ALPHA as a small positive float' do
      expect(mod::REGULATION_ALPHA).to be > 0.0
      expect(mod::REGULATION_ALPHA).to be < 1.0
    end

    it 'has DEFAULT_SKILL in [0, 1]' do
      expect(mod::DEFAULT_SKILL).to be_between(0.0, 1.0)
    end

    it 'has SKILL_GAIN > SKILL_DECAY' do
      expect(mod::SKILL_GAIN).to be > mod::SKILL_DECAY
    end

    it 'has MAX_REGULATION_HISTORY as positive integer' do
      expect(mod::MAX_REGULATION_HISTORY).to be > 0
    end

    it 'has SUPPRESSION_PENALTY_THRESHOLD as positive integer' do
      expect(mod::SUPPRESSION_PENALTY_THRESHOLD).to be > 0
    end
  end
end
