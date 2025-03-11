# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(SpaceInvaders::AlgorithmRegistry) do
  before do
    # Clear registered algorithms before each test
    @original_algorithms = described_class.algorithms.dup
    described_class.algorithms.clear
  end

  after do
    # Restore original algorithms after each test
    described_class.algorithms.clear
    @original_algorithms.each do |name, algorithm|
      described_class.algorithms[name] = algorithm
    end
  end

  describe '.register' do
    it 'registers a new algorithm' do
      test_class = Class.new(SpaceInvaders::DetectionAlgorithm)
      described_class.register('test', test_class)

      expect(described_class.get('test')).to eq(test_class)
    end

    it 'converts the algorithm name to a string' do
      test_class = Class.new(SpaceInvaders::DetectionAlgorithm)
      described_class.register(:test, test_class)

      expect(described_class.get('test')).to eq(test_class)
    end

    it 'overwrites an existing algorithm with the same name' do
      test_class1 = Class.new(SpaceInvaders::DetectionAlgorithm)
      test_class2 = Class.new(SpaceInvaders::DetectionAlgorithm)

      described_class.register('test', test_class1)
      described_class.register('test', test_class2)

      expect(described_class.get('test')).to eq(test_class2)
    end
  end

  describe '.get' do
    it 'returns nil for unknown algorithms' do
      expect(described_class.get('unknown')).to be_nil
    end

    it 'returns the algorithm class for known algorithms' do
      test_class = Class.new(SpaceInvaders::DetectionAlgorithm)
      described_class.register('test', test_class)

      expect(described_class.get('test')).to eq(test_class)
    end

    it 'accepts symbol keys' do
      test_class = Class.new(SpaceInvaders::DetectionAlgorithm)
      described_class.register('test', test_class)

      expect(described_class.get(:test)).to eq(test_class)
    end
  end

  describe '.available_algorithms' do
    it 'returns an empty list when no algorithms are registered' do
      expect(described_class.available_algorithms).to be_empty
    end

    it 'returns the list of registered algorithm names' do
      test_class1 = Class.new(SpaceInvaders::DetectionAlgorithm)
      test_class2 = Class.new(SpaceInvaders::DetectionAlgorithm)

      described_class.register('algo1', test_class1)
      described_class.register('algo2', test_class2)

      expect(described_class.available_algorithms).to contain_exactly('algo1', 'algo2')
    end
  end
end
