# frozen_string_literal: true

module SpaceInvaders
  class NaiveDetectionAlgorithm < DetectionAlgorithm
    def detect
      threshold = @config.min_similarity
      min_visibility = @config.min_visibility
      matches = []

      @invaders.each do |invader|
        (-invader.height + 1..@radar.height).each do |row|
          (-invader.width + 1..@radar.width).each do |col|
            similarity, matching_cells, significant_cells = calculate_similarity_with_bounds(
              invader, row, col
            )

            next unless valid_match?(similarity, significant_cells, invader, threshold,
                                     min_visibility)

            matches << {
              invader: invader,
              position: [row, col],
              similarity: similarity,
              matching_cells: matching_cells,
              significant_cells: significant_cells,
              total_significant_cells: invader.total_significant_cells,
            }
          end
        end
      end

      sorted_matches = matches.sort_by { |match| -match[:similarity] }
      filter_duplicates(sorted_matches)
    end

    private

    def valid_match?(similarity, significant_cells, invader, threshold, min_visibility)
      similarity >= threshold &&
        significant_cells >= (invader.total_significant_cells * min_visibility)
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
  end
end
