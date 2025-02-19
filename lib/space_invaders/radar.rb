# frozen_string_literal: true

module SpaceInvaders
  class Radar
    attr_reader :grid, :width, :height

    def initialize(raw_data)
      @grid = raw_data.split("\n").map(&:chars)
      @height = @grid.length
      @width = @grid.first.length
    end
  end
end
