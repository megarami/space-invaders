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

  let(:config) { SpaceInvaders::Configuration.new(invader_types: ['test']) }
  let(:test_invader_class) do
    Class.new(SpaceInvaders::Invader) do
      initialize_pattern("-o\noo", 'test')
    end
  end

  before do
    # Mock the InvaderLoader to return our test invader
    allow(SpaceInvaders::InvaderLoader).to(receive(:load_invaders).and_return([test_invader_class]))
  end

  describe '#initialize' do
    subject(:service) { described_class.new(radar_data, config) }

    it 'creates a radar from the provided data' do
      expect(service.radar).to(be_a(SpaceInvaders::Radar))
      expect(service.radar.width).to(eq(10))
      expect(service.radar.height).to(eq(10))
    end

    it 'filters invaders based on config' do
      # Test we can get the invaders through the class instance variable
      invaders = service.instance_variable_get(:@invaders)
      expect(invaders.size).to(eq(1))
      expect(invaders.first).to(eq(test_invader_class))
    end
  end

  describe '#detect' do
    subject(:service) { described_class.new(radar_data, config) }

    it 'delegates detection to the Detector class' do
      detector_mock = instance_double(SpaceInvaders::Detector)
      expect(SpaceInvaders::Detector).to(receive(:new).and_return(detector_mock))
      expect(detector_mock).to(receive(:detect).and_return([]))

      results = service.detect
      expect(results).to(eq([]))
    end
  end

  context 'with invalid invader type' do
    let(:nonexistent_config) { SpaceInvaders::Configuration.new(invader_types: ['nonexistent']) }

    it 'raises an error when an invalid invader type is specified' do
      expect do
        described_class.new(radar_data,
                            nonexistent_config)
      end.to(raise_error(ArgumentError, /No valid invader types specified/))
    end
  end

  context 'with "all" invader type' do
    let(:all_config) { SpaceInvaders::Configuration.new(invader_types: ['all']) }

    it 'loads all available invader types' do
      service = described_class.new(radar_data, all_config)
      invaders = service.instance_variable_get(:@invaders)
      expect(invaders).to(eq([test_invader_class]))
    end
  end
end
