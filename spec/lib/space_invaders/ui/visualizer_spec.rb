# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(SpaceInvaders::Visualizer) do
  let(:radar_data) do
    [
      '----------',
      '---oo-----',
      '--oooo----',
      '-oooooo---',
      'oo-oo-oo--',
      'oooooooo--',
      '--o--o----',
      '-o-oo-o---',
      'o-o--o-o--',
      '----------',
    ].join("\n")
  end

  let(:radar) { SpaceInvaders::Radar.new(radar_data) }

  let(:small_invader_pattern) do
    [
      '---oo---',
      '--oooo--',
      '-oooooo-',
      'oo-oo-oo',
      'oooooooo',
      '--o--o--',
      '-o-oo-o-',
      'o-o--o-o',
    ].join("\n")
  end

  let(:small_invader) do
    klass = Class.new(SpaceInvaders::Invader)
    klass.initialize_pattern(small_invader_pattern, 'small')
    klass
  end

  let(:matches) do
    [
      {
        invader: small_invader,
        position: [1, 0],
        similarity: 1.0,
        matching_cells: 24,
        significant_cells: 24,
        total_significant_cells: 24,
      },
    ]
  end

  describe '#initialize' do
    it 'creates a visualizer with default format' do
      visualizer = described_class.new(radar, matches)
      expect(visualizer.instance_variable_get(:@format)).to eq('text')
    end

    it 'creates a visualizer with specified format' do
      visualizer = described_class.new(radar, matches, 'ascii')
      expect(visualizer.instance_variable_get(:@format)).to eq('ascii')
    end

    it 'determines if color is enabled' do
      allow($stdout).to receive(:tty?).and_return(true)

      visualizer = described_class.new(radar, matches)
      expect(visualizer.instance_variable_get(:@color_enabled)).to be(true)

      # ASCII format should not use color
      visualizer = described_class.new(radar, matches, 'ascii')
      expect(visualizer.instance_variable_get(:@color_enabled)).to be(false)
    end

    it 'generates invader colors' do
      visualizer = described_class.new(radar, matches)
      invader_colors = visualizer.instance_variable_get(:@invader_colors)

      expect(invader_colors).to be_a(Hash)
      expect(invader_colors).to have_key('small')
      expect(described_class::COLORS.keys).to include(invader_colors['small'])
    end
  end

  describe '#visualize_match' do
    subject(:visualizer) { described_class.new(radar, matches) }

    it 'generates a text representation of a match' do
      result = visualizer.visualize_match(matches.first)

      expect(result).to be_a(String)
      expect(result).to include('Invader: small')
      expect(result).to include('Position: (1, 0)')
      expect(result).to include('Match similarity: 100.0%')
    end

    it 'includes border and legend when appropriate' do
      allow($stdout).to receive(:tty?).and_return(false)
      visualizer = described_class.new(radar, matches)

      result = visualizer.visualize_match(matches.first)

      # Should not have colored legend when color is disabled
      expect(result).not_to include('Legend:')
    end

    it 'handles edge cases near radar boundaries' do
      edge_match = {
        invader: small_invader,
        position: [-2, -2], # Partially outside radar
        similarity: 0.7,
        matching_cells: 12,
        significant_cells: 17,
        total_significant_cells: 24,
      }

      result = visualizer.visualize_match(edge_match)

      # Should still generate valid output
      expect(result).to be_a(String)
      expect(result).to include('Position: (-2, -2)')
      expect(result).to include('Match similarity: 70.0%')
    end
  end

  describe '#visualize_full_radar' do
    subject(:visualizer) { described_class.new(radar, matches) }

    it 'generates a full visualization of the radar with matches' do
      result = visualizer.visualize_full_radar

      expect(result).to be_a(String)
      expect(result.lines.count).to be >= radar.height
    end

    it 'includes a legend when color is enabled' do
      allow($stdout).to receive(:tty?).and_return(true)
      colored_visualizer = described_class.new(radar, matches)

      result = colored_visualizer.visualize_full_radar

      expect(result).to include('Legend:')
    end

    it 'handles multiple matches' do
      multiple_matches = [
        matches.first,
        {
          invader: small_invader,
          position: [2, 2],
          similarity: 0.9,
          matching_cells: 22,
          significant_cells: 24,
          total_significant_cells: 24,
        },
      ]

      multi_visualizer = described_class.new(radar, multiple_matches)
      result = multi_visualizer.visualize_full_radar

      expect(result.lines.count).to be >= radar.height
    end

    it 'handles empty matches array' do
      empty_visualizer = described_class.new(radar, [])
      result = empty_visualizer.visualize_full_radar

      # Should still produce the radar visualization without errors
      expect(result.lines.count).to be >= radar.height
    end
  end

  describe '#create_legend' do
    it 'returns appropriate legend when color is enabled' do
      allow($stdout).to receive(:tty?).and_return(true)
      visualizer = described_class.new(radar, matches)

      legend = visualizer.create_legend

      expect(legend).to include('Legend:')
      expect(legend).to include('Small Invader')
    end

    it 'returns empty string when color is disabled' do
      allow($stdout).to receive(:tty?).and_return(false)
      visualizer = described_class.new(radar, matches)

      legend = visualizer.create_legend

      expect(legend).to eq('')
    end
  end

  describe 'private methods' do
    subject(:visualizer) { described_class.new(radar, matches) }

    describe '#mark_invader' do
      it 'marks invader on the grid' do
        grid = radar.grid.map(&:dup)
        visualizer.send(:mark_invader, grid, matches.first)

        # Grid should be modified with marked cells
        original_grid = radar.grid
        expect(grid).not_to eq(original_grid)
      end
    end

    describe '#get_color_for_invader_type' do
      it 'returns color for known invader type' do
        invader_colors = { 'small' => :red }
        visualizer.instance_variable_set(:@invader_colors, invader_colors)

        color = visualizer.send(:get_color_for_invader_type, 'small')
        expect(color).to eq(:red)
      end

      it 'returns nil for unknown invader type' do
        invader_colors = { 'small' => :red }
        visualizer.instance_variable_set(:@invader_colors, invader_colors)

        color = visualizer.send(:get_color_for_invader_type, 'unknown')
        expect(color).to be_nil
      end
    end

    describe '#colorize' do
      it 'adds color codes when color is enabled' do
        visualizer.instance_variable_set(:@color_enabled, true)

        colored_text = visualizer.send(:colorize, 'test', :red)
        expect(colored_text).to include(described_class::COLORS[:red])
        expect(colored_text).to include(described_class::COLORS[:reset])
      end

      it 'returns original text when color is disabled' do
        visualizer.instance_variable_set(:@color_enabled, false)

        colored_text = visualizer.send(:colorize, 'test', :red)
        expect(colored_text).to eq('test')
      end

      it 'returns original text for unknown color' do
        visualizer.instance_variable_set(:@color_enabled, true)

        colored_text = visualizer.send(:colorize, 'test', :nonexistent)
        expect(colored_text).to eq('test')
      end
    end
  end
end
