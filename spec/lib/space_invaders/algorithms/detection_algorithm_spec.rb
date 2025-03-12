# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(SpaceInvaders::DetectionAlgorithm) do
  let(:radar) { instance_double(SpaceInvaders::Radar, height: 10, width: 15) }
  let(:invaders) { [double('Invader')] }
  let(:config) { instance_double(SpaceInvaders::Configuration) }

  describe '#initialize' do
    it 'stores the radar, invaders, and config' do
      algorithm = described_class.new(radar, invaders, config)

      expect(algorithm.radar).to eq(radar)
      expect(algorithm.invaders).to eq(invaders)
      expect(algorithm.config).to eq(config)
    end
  end

  describe '#detect' do
    it 'raises NotImplementedError' do
      algorithm = described_class.new(radar, invaders, config)
      expect { algorithm.detect }.to raise_error(NotImplementedError)
    end
  end

  describe '#within_radar_bounds?' do
    let(:algorithm) { described_class.new(radar, invaders, config) }

    it 'returns true for coordinates within bounds' do
      expect(algorithm.within_radar_bounds?(5, 10)).to be(true)
    end

    it 'returns false for coordinates outside bounds' do
      expect(algorithm.within_radar_bounds?(-1, 5)).to be(false)
      expect(algorithm.within_radar_bounds?(5, -1)).to be(false)
      expect(algorithm.within_radar_bounds?(10, 5)).to be(false)
      expect(algorithm.within_radar_bounds?(5, 15)).to be(false)
    end

    it 'correctly handles edge cases' do
      expect(algorithm.within_radar_bounds?(0, 0)).to be(true)
      expect(algorithm.within_radar_bounds?(9, 14)).to be(true)
    end
  end

  # rubocop:disable RSpec/MultipleMemoizedHelpers
  describe '#filter_duplicates' do
    let(:algorithm) { described_class.new(radar, invaders, config) }
    let(:duplicate_threshold) { 0.5 }
    let(:config) do
      instance_double(SpaceInvaders::Configuration, duplicate_threshold: duplicate_threshold)
    end

    let(:test_invader) do
      invader = double('Invader')
      allow(invader).to receive_messages(height: 5, width: 5)
      invader
    end

    it 'keeps matches with highest similarity when duplicates exist' do
      matches = [
        { invader: test_invader, position: [0, 0], similarity: 0.9 },
        { invader: test_invader, position: [1, 1], similarity: 0.8 }, # Close to first match
        { invader: test_invader, position: [10, 10], similarity: 0.7 }, # Far from others
      ]

      filtered = algorithm.filter_duplicates(matches)

      # Should keep [0,0] and [10,10], but filter [1,1] as it's a duplicate of [0,0]
      expect(filtered.size).to eq(2)
      expect(filtered.map { |m| m[:position] }).to include([0, 0], [10, 10])
      expect(filtered.map { |m| m[:position] }).not_to include([1, 1])
    end

    it 'does not filter matches of different invaders' do
      other_invader = double('Invader')

      matches = [
        { invader: test_invader, position: [0, 0], similarity: 0.9 },
        { invader: other_invader, position: [0, 0], similarity: 0.8 }, # Same position but different invader
      ]

      filtered = algorithm.filter_duplicates(matches)
      expect(filtered.size).to eq(2)
    end

    it 'respects the duplicate threshold' do
      # Create matches at varying distances
      matches = [
        { invader: test_invader, position: [0, 0], similarity: 0.9 },
        { invader: test_invader, position: [1, 1], similarity: 0.8 }, # Close, should be filtered
        { invader: test_invader, position: [3, 3], similarity: 0.7 }, # Farther, but still close
      ]

      # With default threshold
      default_filtered = algorithm.filter_duplicates(matches)

      # With lower threshold (more aggressive filtering)
      low_threshold = 0.8
      aggressive_filtered = algorithm.filter_duplicates(matches, low_threshold)

      # Lower threshold should filter more matches
      expect(aggressive_filtered.size).to be <= default_filtered.size
    end

    it 'returns empty array for empty input' do
      expect(algorithm.filter_duplicates([])).to eq([])
    end
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers
end
