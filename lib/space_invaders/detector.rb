# frozen_string_literal: true

module SpaceInvaders
  class Detector
    attr_reader :radar

    def initialize(radar, invaders, config = Configuration.new)
      @radar = radar
      @invaders = invaders
      @config = config
    end

    def detect(min_similarity = nil)
      threshold = min_similarity || @config.min_similarity
      min_visibility = @config.min_visibility
      duplicate_threshold = @config.duplicate_threshold
      matches = []

      @invaders.each do |invader|
        (-invader.height + 1..@radar.height).each do |row|
          (-invader.width + 1..@radar.width).each do |col|
            similarity, matching_cells, significant_cells = calculate_similarity_with_bounds(invader,
                                                                                             row,
                                                                                             col)

            # Only consider matches with enough visible pattern and sufficient similarity
            next if similarity < threshold || significant_cells < (invader.total_significant_cells * min_visibility)

            matches << {
              invader: invader,
              position: [row, col],
              similarity: similarity,
              matching_cells: matching_cells,
              significant_cells: significant_cells,
              total_significant_cells: invader.total_significant_cells
            }
          end
        end
      end

      sorted_matches = matches.sort_by { |match| -match[:similarity] }
      filter_duplicates(sorted_matches, duplicate_threshold)
    end

    def calculate_similarity_with_bounds(invader, start_row, start_col)
      matching_cells = 0
      significant_cells = 0

      invader.pattern.each_with_index do |pattern_row, row_offset|
        pattern_row.each_with_index do |pattern_cell, col_offset|
          grid_row = start_row + row_offset
          grid_col = start_col + col_offset

          # Skip if outside radar bounds
          next unless within_radar_bounds?(grid_row, grid_col)

          # Only count 'o' cells in the pattern as significant
          next unless pattern_cell == 'o'

          significant_cells += 1
          grid_cell = @radar.grid[grid_row][grid_col]
          matching_cells += 1 if grid_cell == pattern_cell
        end
      end

      # Calculate similarity based only on significant visible cells
      return [0, 0, significant_cells] if significant_cells.zero?

      similarity = matching_cells.to_f / significant_cells

      [similarity, matching_cells, significant_cells]
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

    def within_radar_bounds?(row, col)
      row >= 0 && row < @radar.height && col >= 0 && col < @radar.width
    end
  end
end
