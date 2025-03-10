# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(SpaceInvaders) do
  describe 'VERSION' do
    it 'has a version number' do
      expect(SpaceInvaders::VERSION).not_to(be(nil))
    end
  end

  describe 'module structure' do
    it 'includes the required modules and classes' do
      # Core classes should be defined
      expect(defined?(SpaceInvaders::Invader)).to(eq('constant'))
      expect(defined?(SpaceInvaders::Radar)).to(eq('constant'))
      expect(defined?(SpaceInvaders::Configuration)).to(eq('constant'))
      expect(defined?(SpaceInvaders::Detector)).to(eq('constant'))
      expect(defined?(SpaceInvaders::DetectorService)).to(eq('constant'))
      expect(defined?(SpaceInvaders::Visualizer)).to(eq('constant'))
    end
  end

  describe 'InvaderLoader' do
    it 'loads invader patterns' do
      # Check that loader functionality works
      invaders = SpaceInvaders::InvaderLoader.load_invaders
      expect(invaders).to(be_an(Array))
      expect(invaders).not_to(be_empty)

      # Verify at least one invader class exists
      expect(invaders.first).to(be < SpaceInvaders::Invader)
    end

    it 'has a patterns directory' do
      expect(SpaceInvaders::InvaderLoader::PATTERNS_DIR).to(be_a(String))
      expect(Dir.exist?(SpaceInvaders::InvaderLoader::PATTERNS_DIR)).to(be(true))
    end
  end
end
