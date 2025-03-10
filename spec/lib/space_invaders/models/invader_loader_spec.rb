# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'

RSpec.describe(SpaceInvaders::InvaderLoader) do
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

  before do
    # Store original patterns directory
    @original_patterns_dir = SpaceInvaders::InvaderLoader::PATTERNS_DIR

    # Override the constant for testing
    SpaceInvaders::InvaderLoader.send(:remove_const, :PATTERNS_DIR)
    SpaceInvaders::InvaderLoader.const_set(:PATTERNS_DIR, test_patterns_dir)

    # Create test directory and pattern files
    FileUtils.mkdir_p(test_patterns_dir)
    File.write(File.join(test_patterns_dir, 'small.txt'), small_pattern)
    File.write(File.join(test_patterns_dir, 'large.txt'), large_pattern)

    # Remove existing test invader classes if they exist
    %w[Small Large].each do |name|
      SpaceInvaders.send(:remove_const, "#{name}Invader") if SpaceInvaders.const_defined?("#{name}Invader")
    end
  end

  after do
    # Clean up test directory
    FileUtils.rm_rf(test_patterns_dir)

    # Restore original patterns directory
    SpaceInvaders::InvaderLoader.send(:remove_const, :PATTERNS_DIR)
    SpaceInvaders::InvaderLoader.const_set(:PATTERNS_DIR, @original_patterns_dir)

    # Remove test invader classes
    %w[Small Large].each do |name|
      SpaceInvaders.send(:remove_const, "#{name}Invader") if SpaceInvaders.const_defined?("#{name}Invader")
    end
  end

  describe '.load_invaders' do
    it 'loads invaders from pattern files' do
      invaders = described_class.load_invaders
      expect(invaders.size).to(eq(2))
    end

    it 'creates invader classes for each pattern' do
      described_class.load_invaders
      expect(SpaceInvaders.const_defined?('SmallInvader')).to(be(true))
      expect(SpaceInvaders.const_defined?('LargeInvader')).to(be(true))
    end

    it 'initializes patterns correctly' do
      described_class.load_invaders
      small_invader = SpaceInvaders::SmallInvader
      large_invader = SpaceInvaders::LargeInvader

      expect(small_invader.name).to(eq('small'))
      expect(large_invader.name).to(eq('large'))

      expect(small_invader.height).to(eq(8))
      expect(large_invader.height).to(eq(8))
    end

    it 'handles empty patterns directory' do
      FileUtils.rm_rf(test_patterns_dir)
      FileUtils.mkdir_p(test_patterns_dir)

      invaders = described_class.load_invaders
      expect(invaders).to(be_empty)
    end

    it 'reuses existing invader classes' do
      # First load
      described_class.load_invaders

      # Create a test class that will be reused
      test_class = SpaceInvaders::SmallInvader

      # Second load should reuse existing classes
      invaders = described_class.load_invaders
      expect(invaders).to(include(test_class))
    end
  end
end
