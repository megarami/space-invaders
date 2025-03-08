# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(SpaceInvaders::Detector) do
  let(:small_invader) { SpaceInvaders::SmallInvader }
  let(:large_invader) { SpaceInvaders::LargeInvader }

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
          '--------'
        ].join("\n")
      end

      let(:radar) { SpaceInvaders::Radar.new(radar_data) }
      let(:detector) { described_class.new(radar, [small_invader]) }

      it 'finds the small invader with perfect similarity' do
        results = detector.detect

        expect(results.size).to(eq(1))
        expect(results.first[:invader]).to(eq(small_invader))
        expect(results.first[:position]).to(eq([1, 0]))
        expect(results.first[:similarity]).to(eq(1.0))
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
          '--------'
        ].join("\n")
      end

      let(:radar) { SpaceInvaders::Radar.new(radar_data) }
      let(:detector) { described_class.new(radar, [small_invader]) }

      it 'finds the small invader with less than perfect similarity' do
        results = detector.detect(0.9) # Lower threshold

        expect(results.size).to(eq(1))

        match = results.first
        expect(match[:invader]).to(eq(small_invader))
        expect(match[:position]).to(eq([1, 0]))

        # Pattern has 24 significant cells, one is different
        expect(match[:similarity]).to(be_within(0.1).of(23.0 / 24.0))
      end

      it 'finds nothing with a higher threshold' do
        results = detector.detect(0.99) # Higher threshold
        expect(results).to(be_empty)
      end
    end

    context 'with a partially visible invader' do
      let(:radar_data) do
        [
          '--o-----o--',
          '---o---o---',
          '--ooooooo--',
          '-oo-ooo-oo-',
          'ooooooooooo' # Only first 5 rows visible
        ].join("\n")
      end

      let(:radar) { SpaceInvaders::Radar.new(radar_data) }
      let(:detector) { described_class.new(radar, [large_invader]) }

      it 'finds the partially visible invader' do
        results = detector.detect(0.7)

        expect(results.size).to(eq(1))
        expect(results.first[:invader]).to(eq(large_invader))
        expect(results.first[:position]).to(eq([0, 0]))

        # Should have 5/8 rows visible, with perfect match
        visible_significant_cells = results.first[:significant_cells]
        total_significant_cells = results.first[:total_significant_cells]

        expect(visible_significant_cells).to(be < total_significant_cells)
        expect(results.first[:similarity]).to(eq(1.0))
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
          '--------------------'
        ].join("\n")
      end

      let(:radar) { SpaceInvaders::Radar.new(radar_data) }
      let(:detector) { described_class.new(radar, [small_invader, large_invader]) }

      it 'finds both invaders' do
        results = detector.detect(0.8)

        expect(results.size).to(eq(2))

        # Check first match (should be small invader)
        expect(results.map { |r| r[:invader] }).to(include(small_invader))

        # Check second match (should be large invader)
        expect(results.map { |r| r[:invader] }).to(include(large_invader))
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
          '--------'
        ].join("\n")
      end

      let(:radar) { SpaceInvaders::Radar.new(radar_data) }
      let(:detector) { described_class.new(radar, [small_invader]) }

      it 'still finds the invader with sufficient similarity' do
        results = detector.detect(0.8) # 80% similarity threshold

        expect(results.size).to(eq(1))
        expect(results.first[:invader]).to(eq(small_invader))
        expect(results.first[:position]).to(eq([1, 0]))
        expect(results.first[:similarity]).to(be < 1.0)
        expect(results.first[:similarity]).to(be >= 0.8)
      end
    end
  end
end
