# frozen_string_literal: true

module SpaceInvaders
  class Invader
    class << self
      attr_reader :pattern, :width, :height, :total_significant_cells

      def initialize_pattern(raw_pattern)
        @pattern = raw_pattern.split("\n").map(&:chars)
        @height = @pattern.length
        @width = @pattern.first.length
        @total_significant_cells = @pattern.sum { |row| row.count('o') }
      end
    end
  end
end
