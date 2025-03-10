# frozen_string_literal: true

require 'spec_helper'
# rubocop:disable RSpec/SpecFilePathFormat
RSpec.describe SpaceInvaders::Invader do
  let(:test_pattern) do
    "-o-\n" \
      "ooo\n" \
      '-o-'
  end

  let(:invader_name) { 'TestInvader' }
  let(:test_class) do
    klass = Class.new(described_class)
    klass.initialize_pattern(test_pattern, invader_name)
    klass
  end

  describe '.initialize_pattern' do
    it 'properly parses the pattern' do
      expect(test_class.pattern).to eq([%w[- o -], %w[o o o], %w[- o -]])
    end

    it 'sets the correct width and height' do
      expect(test_class.width).to eq(3)
      expect(test_class.height).to eq(3)
    end

    it 'correctly counts significant cells' do
      expect(test_class.total_significant_cells).to eq(5)
    end

    it 'sets the name' do
      expect(test_class.name).to eq(invader_name)
    end
  end

  describe 'with complex pattern' do
    let(:complex_pattern) do
      "--o--\n" \
        "-ooo-\n" \
        "ooooo\n" \
        "--o--\n" \
        '-o-o-'
    end

    let(:complex_class) do
      klass = Class.new(described_class)
      klass.initialize_pattern(complex_pattern, 'ComplexInvader')
      klass
    end

    it 'handles patterns with varied significant cells' do
      expect(complex_class.total_significant_cells).to eq(12)
      expect(complex_class.width).to eq(5)
      expect(complex_class.height).to eq(5)
    end
  end
end
# rubocop:enable RSpec/SpecFilePathFormat
