# frozen_string_literal: true

module SpaceInvaders
  # Implementation of a block scanning detection algorithm
  # This algorithm marks regions as "blocked" once an invader is found
  class BlockScanningAlgorithm < DetectionAlgorithm
    def detect
      threshold = @config.min_similarity
      min_visibility = @config.min_visibility
      matches = []

      # Create a matrix to track blocked regions
      blocked = Array.new(@radar.height) { Array.new(@radar.width, false) }

      # Sort invaders by size (largest first) to prioritize larger patterns
      sorted_invaders = @invaders.sort_by { |invader| -invader.total_significant_cells }

      sorted_invaders.each do |invader|
        # For each position in the radar
        (0...@radar.height).each do |row|
          (0...@radar.width).each do |col|
            # Skip if this position is already blocked
            next if blocked[row][col]

            # Skip if this would place the invader completely outside bounds
            next if row + invader.height <= 0 || row >= @radar.height
            next if col + invader.width <= 0 || col >= @radar.width

            # Calculate similarity
            similarity, matching_cells, significant_cells = calculate_similarity_with_bounds(
              invader, row, col
            )

            # Skip if not enough of the pattern is visible or similarity is too low
            if similarity < threshold ||
               significant_cells < (invader.total_significant_cells * min_visibility)
              next
            end

            # Found a match, add it to results
            matches << {
              invader: invader,
              position: [row, col],
              similarity: similarity,
              matching_cells: matching_cells,
              significant_cells: significant_cells,
              total_significant_cells: invader.total_significant_cells,
            }

            # Block this region to avoid overlapping matches
            block_region(blocked, row, col, invader.height, invader.width)
          end
        end
      end

      # Sort matches by similarity (best matches first)
      matches.sort_by { |match| -match[:similarity] }
    end

    private

    # Mark a region as blocked
    def block_region(blocked, start_row, start_col, height, width)
      # Calculate effective blocking area
      block_start_row = [start_row, 0].max
      block_start_col = [start_col, 0].max
      block_end_row = [start_row + height, blocked.length].min
      block_end_col = [start_col + width, blocked[0].length].min

      # Mark all cells in this region as blocked
      (block_start_row...block_end_row).each do |r|
        (block_start_col...block_end_col).each do |c|
          blocked[r][c] = true
        end
      end
    end

    # Calculate similarity between an invader pattern and the radar at a given position
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
