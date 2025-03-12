# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'

RSpec.describe SpaceInvaders::InvaderLoader do
  let(:test_patterns_dir) { File.join(Dir.tmpdir, "test_patterns_#{Time.now.to_i}") }
  let(:small_pattern) do
    "---oo---\n" \
      "--oooo--\n" \
      "-oooooo-\n" \
      "oo-oo-oo\n" \
      "oooooooo\n" \
      "--o--o--\n" \
      "-o-oo-o-\n" \
      'o-o--o-o'
  end
  let(:large_pattern) do
    "--o-----o--\n" \
      "---o---o---\n" \
      "--ooooooo--\n" \
      "-oo-ooo-oo-\n" \
      "ooooooooooo\n" \
      "o-ooooooo-o\n" \
      "o-o-----o-o\n" \
      '---oo-oo---'
  end
  let(:custom_pattern) do
    "o-o\n" \
      "-o-\n" \
      'o-o'
  end

  before do
    # Create test directory and pattern files
    FileUtils.mkdir_p(test_patterns_dir)
    File.write(File.join(test_patterns_dir, 'small.txt'), small_pattern)
    File.write(File.join(test_patterns_dir, 'large.txt'), large_pattern)
    File.write(File.join(test_patterns_dir, 'custom.txt'), custom_pattern)

    # Stub the constant
    stub_const("#{described_class}::PATTERNS_DIR", test_patterns_dir)
  end

  after do
    FileUtils.rm_rf(test_patterns_dir)
  end

  describe '.load_invaders' do
    it 'loads invaders from pattern files with default config' do
      invaders = described_class.load_invaders
      expect(invaders.size).to eq(3)
      expect(invaders.map(&:name)).to include('small', 'large', 'custom')
    end

    it 'filters invaders based on config invader_types' do
      # Config with specific invader types
      config = SpaceInvaders::Configuration.new(invader_types: %w[small custom])

      invaders = described_class.load_invaders(config)
      expect(invaders.size).to eq(2)
      expect(invaders.map(&:name)).to include('small', 'custom')
      expect(invaders.map(&:name)).not_to include('large')
    end

    it 'loads all invaders when config specifies "all"' do
      config = SpaceInvaders::Configuration.new(invader_types: ['all'])

      invaders = described_class.load_invaders(config)
      expect(invaders.size).to eq(3)
      expect(invaders.map(&:name)).to include('small', 'large', 'custom')
    end

    it 'creates invader classes for each pattern' do
      described_class.load_invaders
      expect(SpaceInvaders.const_defined?(:SmallInvader)).to be(true)
      expect(SpaceInvaders.const_defined?(:LargeInvader)).to be(true)
      expect(SpaceInvaders.const_defined?(:CustomInvader)).to be(true)
    end

    it 'initializes patterns correctly' do # rubocop:disable RSpec/MultipleExpectations
      described_class.load_invaders
      small_invader = SpaceInvaders::SmallInvader
      large_invader = SpaceInvaders::LargeInvader
      custom_invader = SpaceInvaders::CustomInvader

      expect(small_invader.name).to eq('small')
      expect(large_invader.name).to eq('large')
      expect(custom_invader.name).to eq('custom')

      expect(small_invader.height).to eq(8)
      expect(large_invader.height).to eq(8)
      expect(custom_invader.height).to eq(3)
    end

    it 'handles empty patterns directory' do
      FileUtils.rm_rf(test_patterns_dir)
      FileUtils.mkdir_p(test_patterns_dir)

      expect { described_class.load_invaders }.to raise_error(ArgumentError, /No valid invader types specified/)
    end

    it 'reuses existing invader classes' do
      # First load
      described_class.load_invaders

      # Create a test class that will be reused
      test_class = SpaceInvaders::SmallInvader

      # Second load should reuse existing classes
      invaders = described_class.load_invaders
      expect(invaders).to include(test_class)
    end

    it 'raises an error when no valid invader types are found' do
      config = SpaceInvaders::Configuration.new(invader_types: ['nonexistent'])

      expect { described_class.load_invaders(config) }.to raise_error(ArgumentError, /No valid invader types specified/)
    end
  end
end
