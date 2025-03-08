# frozen_string_literal: true

module SpaceInvaders
  class Invader
    class << self
      attr_reader :pattern, :width, :height, :total_significant_cells

      def initialize_pattern(raw_pattern)
        @pattern = parse_pattern(raw_pattern)
        @height = @pattern.length
        @width = @pattern.first.length
        @total_significant_cells = count_significant_cells
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
end
