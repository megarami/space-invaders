#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/space_invaders'
require 'optparse'

module SpaceInvaders
  class Runner
    DEFAULT_CONFIG = {
      min_similarity: 0.7,
      invader_types: %w[large small]
    }.freeze

    def initialize
      @config = DEFAULT_CONFIG.dup
      parse_options
    end

    def run
      unless File.exist?(@radar_file)
        puts("Error: Radar file '#{@radar_file}' not found.")
        exit(1)
      end

      radar_data = File.read(@radar_file)
      @invaders = load_invaders
      detector = Detector.new(radar_data, @invaders)
      results = detector.detect(@config[:min_similarity])

      if results.empty?
        puts('No invaders detected in the radar sample.')
      else
        output_results(results)
      end
    end

    private

    def load_invaders
      invaders = []

      invaders << LargeInvader if @config[:invader_types].include?('large')

      invaders << SmallInvader if @config[:invader_types].include?('small')
    end

    def parse_options
      opt_parser = OptionParser.new do |opts|
        opts.banner = 'Usage: run_detector.rb [options] RADAR_FILE'

        opts.on('-s', '--similarity FLOAT', Float,
                "Minimum similarity threshold (default: #{DEFAULT_CONFIG[:min_similarity]})") do |s|
          @config[:min_similarity] = s
        end

        opts.on('-i', '--invaders LIST', Array,
                "Invader types to detect: large, small, or both (default: #{DEFAULT_CONFIG[:invader_types].join(',')})") do |list|
          @config[:invader_types] = list
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

    def output_results(results)
      results.each do |result|
        puts("Invader detected: #{result[:invader].name}")
        puts("Similarity: #{result[:similarity]}")
        puts("Position: #{result[:position]}")
        puts
      end
    end
  end
end

SpaceInvaders::Runner.new.run if __FILE__ == $PROGRAM_NAME
