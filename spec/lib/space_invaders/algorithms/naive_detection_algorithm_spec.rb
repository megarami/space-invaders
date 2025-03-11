# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(SpaceInvaders::NaiveDetectionAlgorithm) do
  let(:small_invader) { SpaceInvaders::SmallInvader }
  let(:large_invader) { SpaceInvaders::LargeInvader }
  let(:config) do
    instance_double(SpaceInvaders::Configuration,
                    min_similarity: 0.7,
                    min_visibility: 0.5,
                    duplicate_threshold: 0.7)
  end

  describe '#detect' do
    context 'with an exact match' do
      let(:radar_data) do
        [
          '--------',
          '---oo---',
          '--oooo--',
          '-oooooo-',
          'oo-oo-oo',
          'oooooooo',
          '--o--o--',
          '-o-oo-o-',
          'o-o--o-o',
          '--------',
        ].join("\n")
      end

      let(:radar) { SpaceInvaders::Radar.new(radar_data) }
      let(:algorithm) { described_class.new(radar, [small_invader], config) }

      it 'finds the small invader with perfect similarity' do
        results = algorithm.detect

        expect(results.size).to eq(1)
        expect(results.first[:invader]).to eq(small_invader)
        expect(results.first[:position]).to eq([1, 0])
        expect(results.first[:similarity]).to eq(1.0)
      end
    end

    context 'with a partial match' do
      let(:radar_data) do
        [
          '--------',
          '---ox---', # One cell different
          '--oooo--',
          '-oooooo-',
          'oo-oo-oo',
          'oooooooo',
          '--o--o--',
          '-o-oo-o-',
          'o-o--o-o',
          '--------',
        ].join("\n")
      end

      let(:radar) { SpaceInvaders::Radar.new(radar_data) }
      let(:algorithm) { described_class.new(radar, [small_invader], config) }
      let(:lower_threshold_config) do
        instance_double(SpaceInvaders::Configuration,
                        min_similarity: 0.9,
                        min_visibility: 0.5,
                        duplicate_threshold: 0.7)
      end
      let(:higher_threshold_config) do
        instance_double(SpaceInvaders::Configuration,
                        min_similarity: 0.99,
                        min_visibility: 0.5,
                        duplicate_threshold: 0.7)
      end

      it 'finds the small invader with less than perfect similarity' do
        algorithm_with_lower_threshold = described_class.new(radar, [small_invader], lower_threshold_config)
        results = algorithm_with_lower_threshold.detect

        expect(results.size).to eq(1)

        match = results.first
        expect(match[:invader]).to eq(small_invader)
        expect(match[:position]).to eq([1, 0])

        # Pattern has 24 significant cells, one is different
        expect(match[:similarity]).to be_within(0.1).of(23.0 / 24.0)
      end

      it 'finds nothing with a higher threshold' do
        algorithm_with_higher_threshold = described_class.new(radar, [small_invader], higher_threshold_config)
        results = algorithm_with_higher_threshold.detect
        expect(results).to be_empty
      end
    end

    context 'with a partially visible invader' do
      let(:radar_data) do
        [
          '--o-----o--',
          '---o---o---',
          '--ooooooo--',
          '-oo-ooo-oo-',
          'ooooooooooo', # Only first 5 rows visible
        ].join("\n")
      end

      let(:radar) { SpaceInvaders::Radar.new(radar_data) }
      let(:partial_visibility_config) do
        instance_double(SpaceInvaders::Configuration,
                        min_similarity: 0.7,
                        min_visibility: 0.5,
                        duplicate_threshold: 0.7)
      end
      let(:algorithm) { described_class.new(radar, [large_invader], partial_visibility_config) }

      it 'finds the partially visible invader' do
        results = algorithm.detect

        expect(results.size).to eq(1)
        expect(results.first[:invader]).to eq(large_invader)
        expect(results.first[:position]).to eq([0, 0])

        # Should have 5/8 rows visible, with perfect match
        visible_significant_cells = results.first[:significant_cells]
        total_significant_cells = results.first[:total_significant_cells]

        expect(visible_significant_cells).to be < total_significant_cells
        expect(results.first[:similarity]).to eq(1.0)
      end
    end

    context 'with multiple invaders' do
      let(:radar_data) do
        [
          '--------------------',
          '---oo-------o-----o',
          '--oooo------o---o--',
          '-oooooo---ooooooo--',
          'oo-oo-oo--oo-ooo-oo',
          'oooooooo-ooooooooo-',
          '--o--o---o-ooooooo-',
          '-o-oo-o--o-o-----o-',
          'o-o--o-----oo-oo---',
          '--------------------',
        ].join("\n")
      end

      let(:radar) { SpaceInvaders::Radar.new(radar_data) }
      let(:multiple_invaders_config) do
        instance_double(SpaceInvaders::Configuration,
                        min_similarity: 0.8,
                        min_visibility: 0.5,
                        duplicate_threshold: 0.7)
      end
      let(:algorithm) { described_class.new(radar, [small_invader, large_invader], multiple_invaders_config) }

      it 'finds both invaders' do
        results = algorithm.detect

        expect(results.size).to eq(2)

        # Check first match (should be small invader)
        expect(results.map { |r| r[:invader] }).to include(small_invader)

        # Check second match (should be large invader)
        expect(results.map { |r| r[:invader] }).to include(large_invader)
      end
    end

    context 'with noise in the radar' do
      let(:radar_data) do
        [
          '--------',
          '---oo---',
          '--ooxo--', # Noise: extra 'x'
          '-oooooo-',
          'oo-oo-ox', # Noise: changed '-' to 'x'
          'oooooooo',
          '--o--o--',
          '-o-oo-o-',
          'o-o--o-o',
          '--------',
        ].join("\n")
      end

      let(:radar) { SpaceInvaders::Radar.new(radar_data) }
      let(:noise_config) do
        instance_double(SpaceInvaders::Configuration,
                        min_similarity: 0.8,
                        min_visibility: 0.5,
                        duplicate_threshold: 0.7)
      end
      let(:algorithm) { described_class.new(radar, [small_invader], noise_config) }

      it 'still finds the invader with sufficient similarity' do
        results = algorithm.detect

        expect(results.size).to eq(1)
        expect(results.first[:invader]).to eq(small_invader)
        expect(results.first[:position]).to eq([1, 0])
        expect(results.first[:similarity]).to be < 1.0
        expect(results.first[:similarity]).to be >= 0.8
      end
    end

    context 'with duplicate filtering' do
      let(:radar_data) do
        [
          '------------',
          '---oo---oo--',
          '--oooo-oooo-',
          '-oooooo-oooo',
          'oo-oo-oo-oo-',
          '------------',
        ].join("\n")
      end

      let(:radar) { SpaceInvaders::Radar.new(radar_data) }
      let(:high_duplicate_threshold_config) do
        instance_double(SpaceInvaders::Configuration,
                        min_similarity: 0.7,
                        min_visibility: 0.5,
                        duplicate_threshold: 0.9) # High threshold -> more matches filtered
      end

      let(:low_duplicate_threshold_config) do
        instance_double(SpaceInvaders::Configuration,
                        min_similarity: 0.7,
                        min_visibility: 0.5,
                        duplicate_threshold: 0.3) # Low threshold -> fewer matches filtered
      end

      it 'filters more duplicates with high threshold' do
        high_threshold_algorithm = described_class.new(radar, [small_invader], high_duplicate_threshold_config)
        high_threshold_results = high_threshold_algorithm.detect

        low_threshold_algorithm = described_class.new(radar, [small_invader], low_duplicate_threshold_config)
        low_threshold_results = low_threshold_algorithm.detect

        # High threshold should filter more aggressively
        expect(high_threshold_results.size).to be <= low_threshold_results.size
      end
    end
  end

  describe '#filter_duplicates' do
    let(:radar) { instance_double(SpaceInvaders::Radar) }
    let(:algorithm) { described_class.new(radar, [small_invader], config) }

    it 'removes duplicated matches' do
      # Create matches at same position
      matches = [
        { invader: small_invader, position: [0, 0], similarity: 1.0 },
        { invader: small_invader, position: [0, 1], similarity: 0.9 }, # Close to first match
        { invader: small_invader, position: [10, 10], similarity: 0.8 }, # Far from other matches
      ]

      filtered = algorithm.send(:filter_duplicates, matches)
      expect(filtered.size).to be < matches.size

      # The highest similarity match should be kept
      expect(filtered.map { |m| m[:similarity] }).to include(1.0)
    end

    it 'does not filter matches of different invader types' do
      matches = [
        { invader: small_invader, position: [0, 0], similarity: 1.0 },
        { invader: large_invader, position: [0, 0], similarity: 0.9 }, # Same position but different invader
      ]

      filtered = algorithm.send(:filter_duplicates, matches)
      expect(filtered.size).to eq(2)
    end
  end

  describe '#calculate_similarity_with_bounds' do
    let(:radar_data) { "---\n-o-\n---" }
    let(:radar) { SpaceInvaders::Radar.new(radar_data) }
    let(:algorithm) { described_class.new(radar, [small_invader], config) }
    let(:test_invader) do
      Class.new(SpaceInvaders::Invader) do
        initialize_pattern("-o-\noo-\n-o-", 'test')
      end
    end

    it 'calculates correct similarity for invader pattern' do
      similarity, matching_cells, significant_cells =
        algorithm.send(:calculate_similarity_with_bounds, test_invader, 0, 0)

      expect(significant_cells).to eq(4) # Total 'o' cells in pattern
      expect(matching_cells).to eq(1) # Only one cell matches
      expect(similarity).to eq(0.25) # 1/4 = 0.25
    end

    it 'handles out-of-bounds coordinates' do
      _, _, significant_cells =
        algorithm.send(:calculate_similarity_with_bounds, test_invader, -2, -2)

      # Only a small portion of the invader should be visible
      expect(significant_cells).to be < test_invader.total_significant_cells
    end

    it 'returns zero similarity when no significant cells are visible' do
      similarity, matching_cells, significant_cells =
        algorithm.send(:calculate_similarity_with_bounds, test_invader, -10, -10)

      expect(significant_cells).to eq(0)
      expect(matching_cells).to eq(0)
      expect(similarity).to eq(0)
    end
  end
end
