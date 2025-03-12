# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(SpaceInvaders) do
  before(:all) do # rubocop:disable RSpec/BeforeAfterAll
    SpaceInvaders::AlgorithmRegistry.register('naive', SpaceInvaders::NaiveDetectionAlgorithm)
  end

  describe 'VERSION' do
    it 'has a version number' do
      expect(SpaceInvaders::VERSION).not_to be_nil
    end
  end

  describe 'algorithm registration' do
    it 'registers the default naive algorithm' do
      expect(SpaceInvaders::AlgorithmRegistry.get('naive')).to eq(SpaceInvaders::NaiveDetectionAlgorithm)
    end

    it 'lists available algorithms' do
      expect(SpaceInvaders::AlgorithmRegistry.available_algorithms).to include('naive')
    end
  end

  describe 'InvaderLoader' do
    it 'loads invaders with config filtering' do
      # Create a test configuration
      config = SpaceInvaders::Configuration.new(invader_types: ['all'])

      # Load invaders with config
      invaders = SpaceInvaders::InvaderLoader.load_invaders(config)
      expect(invaders).to be_an(Array)
      expect(invaders).not_to be_empty
    end
  end
end
