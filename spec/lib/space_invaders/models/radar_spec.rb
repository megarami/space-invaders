# frozen_string_literal: true

require 'spec_helper'
# rubocop:disable RSpec/SpecFilePathFormat
RSpec.describe(SpaceInvaders::Radar) do
  describe '#initialize' do
    subject(:radar) { described_class.new(raw_data) }

    let(:raw_data) do
      "ooo\n" \
        "o-o\n" \
        'ooo'
    end

    it 'properly initializes the grid' do
      expect(radar.grid).to eq([%w[o o o], %w[o - o], %w[o o o]])
    end

    it 'correctly sets width and height' do
      expect(radar.width).to eq(3)
      expect(radar.height).to eq(3)
    end
  end

  describe 'with empty data' do
    let(:empty_data) { '' }

    it 'raises an error with empty data' do
      expect { described_class.new(empty_data) }.to raise_error(NoMethodError)
    end
  end

  describe 'with non-rectangular data' do
    subject(:radar) { described_class.new(irregular_data) }

    let(:irregular_data) do
      "oo\n" \
        "ooo\n" \
        'o'
    end

    it 'creates a grid with varying row lengths' do
      expect(radar.grid.map(&:length)).to eq([2, 3, 1])
      expect(radar.width).to eq(2)
    end
  end
end
# rubocop:enable RSpec/SpecFilePathFormat
