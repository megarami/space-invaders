# frozen_string_literal: true

module SpaceInvaders
  # Base class for detection algorithms
  class DetectionAlgorithm
    attr_reader :radar, :invaders, :config

    def initialize(radar, invaders, config)
      @radar = radar
      @invaders = invaders
      @config = config
    end

    def detect
      raise(NotImplementedError, "#{self.class} must implement the detect method")
    end

    # Helper methods that detection algorithms may need
    def within_radar_bounds?(row, col)
      row >= 0 && row < @radar.height && col >= 0 && col < @radar.width
    end

    def filter_duplicates(matches, duplicate_threshold = nil)
      threshold = duplicate_threshold || @config.duplicate_threshold
      filtered = []

      matches.each do |match|
        too_close = filtered.any? do |kept_match|
          next false unless match[:invader] == kept_match[:invader]

          row_diff = (match[:position][0] - kept_match[:position][0]).abs
          col_diff = (match[:position][1] - kept_match[:position][1]).abs

          max_row_diff = (match[:invader].height * threshold).ceil
          max_col_diff = (match[:invader].width * threshold).ceil

          row_diff <= max_row_diff && col_diff <= max_col_diff
        end

        filtered << match unless too_close
      end

      filtered
    end
  end
end
