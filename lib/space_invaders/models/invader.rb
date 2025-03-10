# frozen_string_literal: true

module SpaceInvaders
  # Base invader class
  class Invader
    class << self
      attr_reader :pattern, :width, :height, :total_significant_cells, :name

      def initialize_pattern(raw_pattern, name = nil)
        @pattern = parse_pattern(raw_pattern)
        @height = @pattern.length
        @width = @pattern.first.length
        @total_significant_cells = count_significant_cells
        @name = name
      end

      private

      def parse_pattern(raw_pattern)
        lines = raw_pattern.strip.split("\n")
        lines.map(&:chars)
      end

      def count_significant_cells
        @pattern.sum { |row| row.count('o') }
      end
    end
  end

  # Dynamically load invader patterns from files
  module InvaderLoader
    # Make sure the path is relative to the application's root directory
    PATTERNS_DIR = File.expand_path('../../../patterns', File.dirname(__FILE__))

    def self.load_invaders
      invaders = []

      # Create patterns directory if it doesn't exist
      unless Dir.exist?(PATTERNS_DIR)
        puts("Creating patterns directory at: #{PATTERNS_DIR}")
        Dir.mkdir(PATTERNS_DIR)
      end
      # Load each pattern file and create a corresponding invader class
      Dir.glob(File.join(PATTERNS_DIR, '*.txt')).each do |file|
        invader_name = File.basename(file, '.txt')
        pattern_data = File.read(file)

        # Create class name
        class_name = "#{invader_name.capitalize}Invader"

        # Get or create the invader class
        if SpaceInvaders.const_defined?(class_name)
          # Class already exists, get it
          invader_class = SpaceInvaders.const_get(class_name)
        else
          # Create a new class dynamically for this invader
          invader_class = Class.new(Invader)
          invader_class.initialize_pattern(pattern_data, invader_name)

          # Register the class in the SpaceInvaders module
          SpaceInvaders.const_set(class_name, invader_class)
        end

        # Always add to invaders array
        invaders << invader_class
      end

      invaders
    end
  end
end
