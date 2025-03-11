# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(SpaceInvaders::DetectorService) do
  let(:radar_data) do
    "-o--o-----\n" \
      "--oo------\n" \
      "----------\n" \
      "----------\n" \
      "----------\n" \
      "----------\n" \
      "----------\n" \
      "----------\n" \
      "----------\n" \
      '----------'
  end

  let(:test_invader_class) do
    Class.new(SpaceInvaders::Invader) do
      initialize_pattern("-o\noo", 'test')
    end
  end

  let(:config) do
    SpaceInvaders::Configuration.new(
      invader_types: ['test'],
      algorithm: 'test_algorithm'
    )
  end

  let(:test_algorithm_class) do
    Class.new(SpaceInvaders::DetectionAlgorithm) do
      def detect
        [{ result: 'test' }]
      end
    end
  end

  before do
    # Mock the InvaderLoader to return our test invader
    allow(SpaceInvaders::InvaderLoader).to receive(:load_invaders).and_return([test_invader_class])

    # Register test algorithm
    @original_algorithms = SpaceInvaders::AlgorithmRegistry.algorithms
    SpaceInvaders::AlgorithmRegistry.register('test_algorithm', test_algorithm_class)
  end

  after do
    # Restore original algorithms
    SpaceInvaders::AlgorithmRegistry.algorithms.clear
    @original_algorithms.each do |name, algorithm|
      SpaceInvaders::AlgorithmRegistry.algorithms[name] = algorithm
    end
  end

  describe '#initialize' do
    subject(:service) { described_class.new(radar_data, config) }

    it 'creates a radar from the provided data' do
      expect(service.radar).to be_a(SpaceInvaders::Radar)
      expect(service.radar.width).to eq(10)
      expect(service.radar.height).to eq(10)
    end

    it 'loads invaders based on config' do
      expect(service.invaders.size).to eq(1)
      expect(service.invaders.first).to eq(test_invader_class)
    end
  end

  describe '#detect' do
    subject(:service) { described_class.new(radar_data, config) }

    it 'uses the algorithm specified in config' do
      results = service.detect
      expect(results).to eq([{ result: 'test' }])
    end

    it 'raises an error for unknown algorithm' do
      unknown_config = SpaceInvaders::Configuration.new(
        invader_types: ['test'],
        algorithm: 'unknown_algorithm'
      )

      unknown_service = described_class.new(radar_data, unknown_config)

      expect { unknown_service.detect }.to raise_error(ArgumentError, /Unknown algorithm/)
    end

    it 'properly instantiates the algorithm with radar, invaders, and config' do
      # Create a test algorithm that validates its inputs
      validator_class = Class.new(SpaceInvaders::DetectionAlgorithm) do
        def detect
          raise 'Invalid radar' unless @radar.is_a?(SpaceInvaders::Radar)
          raise 'Invalid invaders' unless @invaders.is_a?(Array) && !@invaders.empty?
          raise 'Invalid config' unless @config.is_a?(SpaceInvaders::Configuration)

          ['Success']
        end
      end

      # Register the validator algorithm
      SpaceInvaders::AlgorithmRegistry.register('validator', validator_class)

      # Create config using the validator
      validator_config = SpaceInvaders::Configuration.new(
        invader_types: ['test'],
        algorithm: 'validator'
      )

      # Create service with validator algorithm
      validator_service = described_class.new(radar_data, validator_config)

      # Should not raise any errors
      expect(validator_service.detect).to eq(['Success'])
    end
  end
end
