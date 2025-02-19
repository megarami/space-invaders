# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(SpaceInvaders::Detector) do
  let(:small_invader) { SpaceInvaders::SmallInvader }
  let(:large_invader) { SpaceInvaders::LargeInvader }
  let(:invaders) { [small_invader, large_invader] }

  describe '#detect' do
    context 'exact matches' do
      it 'finds exact matches for small invader' do
        # Create a radar containing an exact small invader pattern
        radar_data = <<~PATTERN
          -----------
          ----oo-----
          ---oooo----
          --oooooo---
          -oo-oo-oo--
          -oooooooo--
          ---o--o----
          --o-oo-o---
          -o-o--o-o--
          -----------
        PATTERN

        radar = SpaceInvaders::Radar.new(radar_data)
        detector = described_class.new(radar, [small_invader])

        results = detector.detect(1.0)

        expect(results.length).to(eq(1))
        expect(results[0][:position]).to(eq([1, 1]))
        expect(results[0][:similarity]).to(eq(1.0))
        expect(results[0][:invader]).to(eq(small_invader))
      end

      it 'finds exact matches for large invader' do
        # Create a radar containing an exact large invader pattern
        radar_data = <<~PATTERN
          --------------
          --o-----o-----
          ---o---o------
          --ooooooo-----
          -oo-ooo-oo----
          ooooooooooo---
          o-ooooooo-o---
          o-o-----o-o---
          ---oo-oo------
          --------------
        PATTERN

        radar = SpaceInvaders::Radar.new(radar_data)
        detector = described_class.new(radar, [large_invader])

        results = detector.detect(1.0)

        expect(results.length).to(eq(1))
        expect(results[0][:position]).to(eq([1, 0]))
        expect(results[0][:similarity]).to(eq(1.0))
        expect(results[0][:invader]).to(eq(large_invader))
      end
    end

    context 'partial matches' do
      it 'finds matches above threshold with noise' do
        # Create a radar with a slightly corrupted small invader (80% similar)
        radar_data = <<~PATTERN
          -----------
          ----oo-----
          ---oooo----
          --ooo-oo--- # one cell changed
          -oo-oo-oo--
          -ooo-oooo-- # two cells changed
          ---o--o----
          --o-oo-o-o- # one cell changed
          -o-o--o-o--
          -----------
        PATTERN

        radar = SpaceInvaders::Radar.new(radar_data)
        detector = described_class.new(radar, [small_invader])

        results = detector.detect(0.75)

        expect(results.length).to(eq(1))
        expect(results[0][:position]).to(eq([1, 1]))
        expect(results[0][:similarity]).to(be_between(0.75, 0.95))
      end

      it "doesn't find matches below threshold" do
        # Create a radar with a heavily corrupted invader
        radar_data = <<~PATTERN
          -----------
          ----oo-----
          ---o--o----
          --o-o-o----
          -o--o--o---
          -o-o-o-o---
          ---o--o----
          --o-oo-o---
          -o-o--o-o--
          -----------
        PATTERN

        radar = SpaceInvaders::Radar.new(radar_data)
        detector = described_class.new(radar, [small_invader])

        results = detector.detect(0.75)

        expect(results).to(be_empty)
      end
    end

    context 'edge cases' do
      it 'finds patterns partially off the left edge' do
        # Create a radar with small invader partially off left edge
        radar_data = <<~PATTERN
          ----------
          oo--------
          oooo------
          oooooo----
          -oo-oo----
          oooooooo--
          o--o------
          -oo-o-----
          o--o-o----
          ----------
        PATTERN

        radar = SpaceInvaders::Radar.new(radar_data)
        detector = described_class.new(radar, [small_invader])

        results = detector.detect(0.7)

        expect(results.length).to(eq(1))
        expect(results[0][:position][1]).to(be < 0) # Column position should be negative
        expect(results[0][:significant_cells]).to(be < small_invader.total_significant_cells)
      end

      it 'finds patterns partially off the top edge' do
        # Create a radar with small invader partially off top edge
        radar_data = <<~PATTERN
          --oooooo---
          -oo-oo-oo--
          -oooooooo--
          ---o--o----
          --o-oo-o---
          -o-o--o-o--
          -----------
        PATTERN

        radar = SpaceInvaders::Radar.new(radar_data)
        detector = described_class.new(radar, [small_invader])

        results = detector.detect(0.7)

        expect(results.length).to(eq(1))
        expect(results[0][:position][0]).to(be < 0) # Row position should be negative
        expect(results[0][:significant_cells]).to(be < small_invader.total_significant_cells)
      end

      it 'finds patterns partially off the right edge' do
        # Create a radar with large invader partially off right edge
        radar_data = <<~PATTERN
          ------------
          o-----o-----
          -o---o------
          ooooooo-----
          o-ooo-o-----
          oooooooo----
          ooooooo-----
          o-----o-----
          -oo-oo------
          ------------
        PATTERN

        radar = SpaceInvaders::Radar.new(radar_data)
        detector = described_class.new(radar, [large_invader])

        results = detector.detect(0.8)

        expect(results.length).to(eq(1))
        expect(results[0][:significant_cells]).to(be < large_invader.total_significant_cells)
      end

      it 'finds patterns partially off the bottom edge' do
        # Create a radar with large invader partially off bottom edge
        radar_data = <<~PATTERN
          --------------
          --o-----o-----
          ---o---o------
          --ooooooo-----
          -oo-ooo-oo----
          ooooooooooo---
          o-ooooooo-o---
        PATTERN

        radar = SpaceInvaders::Radar.new(radar_data)
        detector = described_class.new(radar, [large_invader])

        results = detector.detect(0.7)

        expect(results.length).to(eq(1))
        expect(results[0][:significant_cells]).to(be < large_invader.total_significant_cells)
      end

      it 'respects minimum visibility threshold' do
        # Create a radar with just a tiny part of an invader visible
        radar_data = <<~PATTERN
          --------------
          --o------------
          ---------------
          ---------------
        PATTERN

        radar = SpaceInvaders::Radar.new(radar_data)
        detector = described_class.new(radar, invaders)

        results = detector.detect(0.5)

        # Should not find anything as less than 50% is visible
        expect(results).to(be_empty)
      end
    end

    context 'multiple invaders' do
      it 'finds multiple invaders in the same radar' do
        # Create a radar with both types of invaders
        radar_data = <<~PATTERN
          ---------------------------------
          --o-----o------------------------
          ---o---o-------------------------
          --ooooooo------------------------
          -oo-ooo-oo------------oo---------
          ooooooooooo-----------oooo-------
          o-ooooooo-o----------oooooo------
          o-o-----o-o---------oo-oo-oo-----
          ---oo-oo------------oooooooo-----
          ----------------------o--o-------
          ---------------------o-oo-o------
          --------------------o-o--o-o-----
          ---------------------------------
        PATTERN

        radar = SpaceInvaders::Radar.new(radar_data)
        detector = described_class.new(radar, invaders)

        results = detector.detect(0.8)

        expect(results.length).to(eq(2))

        # Check results are sorted by similarity (descending)
        sorted_results = results.sort_by { |match| -match[:similarity] }
        expect(results).to(eq(sorted_results))

        # Check that we found both types of invaders
        found_invaders = results.map { |match| match[:invader] }
        expect(found_invaders).to(include(small_invader))
        expect(found_invaders).to(include(large_invader))
      end
    end

    context 'with real data' do
      it 'finds invaders in the sample data' do
        # Test with excerpt from the main sample data
        radar_data = <<~PATTERN
          --ooooooo---o---------o---------o----oooo-------------oo-oo-----ooo-oo-----o-------o-oo-oooooooo---o
          -oo-ooo-oo------------o------------oooooooo---o-----o-------o--oooooo-o------------o-o-ooooooo-o----
          ooooooooooo-o------o---o---o-------oo-oo--o--o---------o--o-o-o-ooooo-o--------------oo-o----o-oo-o-
          o-ooooooo-o-----oo-------oo----o----oooooooo-------o----o-o-o-o-----o-o-----o----------ooo-oo--o---o
          o-o-----o-o--o-o---------------o--o--o--ooo---ooo-------o------oo-oo------------o--------o--o-o--o--
          ---oo-oo----------------------------o-oo----------o------o-o-------o-----o----o-----o-oo-o-----o---o
        PATTERN

        radar = SpaceInvaders::Radar.new(radar_data)
        detector = described_class.new(radar, [large_invader])

        results = detector.detect(0.75)

        # Should find at least one large invader
        expect(results).not_to(be_empty)
        expect(results[0][:invader]).to(eq(large_invader))
      end
    end
  end
end
