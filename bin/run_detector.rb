#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/space_invaders'
require 'optparse'

module SpaceInvaders
  class Runner
    def initialize
      @config = Configuration.new
      parse_options
    end

    def run
      unless File.exist?(@radar_file)
        puts("Error: Radar file '#{@radar_file}' not found.")
        exit(1)
      end

      radar_data = File.read(@radar_file)
      detector_service = DetectorService.new(radar_data, @config)
      results = detector_service.detect

      if results.empty?
        puts('No invaders detected in the radar sample.')
      else
        output_results(results, detector_service.radar)
      end
    end

    private

    def parse_options
      opt_parser = OptionParser.new do |opts|
        opts.banner = 'Usage: run_detector.rb [options] RADAR_FILE'

        opts.on('-s', '--similarity FLOAT', Float,
                "Minimum similarity threshold (default: #{Configuration::DEFAULTS[:min_similarity]})") do |s|
          @config.min_similarity = s
        end

        opts.on('-i', '--invaders LIST', Array,
                "Invader types to detect: large, small, or both (default: #{Configuration::DEFAULTS[:invader_types].join(',')})") do |list|
          @config.invader_types = list
        end

        opts.on('--[no-]visualization',
                "Enable/disable visualization (default: #{Configuration::DEFAULTS[:visualization]})") do |v|
          @config.visualization = v
        end

        opts.on('-f', '--format FORMAT', %w[text ascii],
                "Output format: text or ascii (default: #{Configuration::DEFAULTS[:output_format]})") do |f|
          @config.output_format = f
        end

        opts.on('-v', '--visibility FLOAT', Float,
                "Minimum visibility threshold (default: #{Configuration::DEFAULTS[:min_visibility]})") do |v|
          @config.min_visibility = v
        end

        opts.on('-d', '--duplicate-threshold FLOAT', Float,
                "Duplicate detection threshold (default: #{Configuration::DEFAULTS[:duplicate_threshold]})") do |d|
          @config.duplicate_threshold = d
        end

        opts.on('-h', '--help', 'Show this help message') do
          puts(opts)
          exit
        end
      end

      args = opt_parser.parse!(ARGV)

      if args.empty?
        puts(opt_parser)
        exit(1)
      end

      @radar_file = args.first
    end

    def output_results(results, radar)
      visualizer = Visualizer.new(radar, results, @config.output_format)

      puts("Detected #{results.size} potential invaders:")

      results.each_with_index do |match, index|
        puts("\n##{index + 1}: #{match[:invader].name.split('::').last}")
        puts("  Position: [#{match[:position][0]}, #{match[:position][1]}]")
        puts("  Similarity: #{(match[:similarity] * 100).round(2)}%")
        puts("  Matching cells: #{match[:matching_cells]}/#{match[:significant_cells]} (visible pattern)")

        if @config.visualization
          puts("\nVisualization:")
          puts(visualizer.visualize_match(match))
        end
      end

      puts("\nFull radar visualization with all detected invaders:") if @config.visualization
      puts(visualizer.visualize_full_radar) if @config.visualization
    end
  end
end

SpaceInvaders::Runner.new.run if __FILE__ == $PROGRAM_NAME
