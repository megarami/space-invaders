# frozen_string_literal: true

module SpaceInvaders
  # Implementation of a cross-correlation based detection algorithm
  class CrossCorrelationAlgorithm < DetectionAlgorithm
    def detect
      threshold = @config.min_similarity
      min_visibility = @config.min_visibility
      matches = []

      @invaders.each do |invader|
        # Convert invader pattern to numeric matrix (1 for 'o', 0 for anything else)
        invader_matrix = pattern_to_matrix(invader.pattern)

        # Calculate pattern statistics for normalization
        pattern_mean = calculate_mean(invader_matrix)
        pattern_std = calculate_std(invader_matrix, pattern_mean)

        (-invader.height + 1..@radar.height).each do |row|
          (-invader.width + 1..@radar.width).each do |col|
            # Extract radar segment at current position
            radar_segment, visibility = extract_radar_segment(invader, row, col)

            # Skip if not enough of the pattern is visible
            next if visibility < (invader.total_significant_cells * min_visibility)

            # Calculate radar segment statistics for normalization
            radar_mean = calculate_mean(radar_segment)
            radar_std = calculate_std(radar_segment, radar_mean)

            # Calculate normalized cross-correlation
            correlation = calculate_correlation(
              invader_matrix, radar_segment,
              pattern_mean, radar_mean,
              pattern_std, radar_std
            )

            # Skip if correlation is below threshold
            next if correlation < threshold

            # Count matching cells for reference/comparison
            matching_cells = count_matching_cells(invader, row, col)

            matches << {
              invader: invader,
              position: [row, col],
              similarity: correlation,
              matching_cells: matching_cells,
              significant_cells: visibility,
              total_significant_cells: invader.total_significant_cells,
            }
          end
        end
      end

      sorted_matches = matches.sort_by { |match| -match[:similarity] }
      filter_duplicates(sorted_matches)
    end

    private

    # Convert pattern to numeric matrix (1 for 'o', 0 for anything else)
    def pattern_to_matrix(pattern)
      pattern.map do |row|
        row.map { |cell| cell == 'o' ? 1 : 0 }
      end
    end

    # Extract radar segment at given position, handling bounds
    def extract_radar_segment(invader, start_row, start_col)
      segment = Array.new(invader.height) { Array.new(invader.width, 0) }
      visible_cells = 0
      significant_cells = 0

      invader.pattern.each_with_index do |pattern_row, row_offset|
        pattern_row.each_with_index do |pattern_cell, col_offset|
          grid_row = start_row + row_offset
          grid_col = start_col + col_offset

          # Handle cells outside radar bounds
          unless within_radar_bounds?(grid_row, grid_col)
            segment[row_offset][col_offset] = 0
            next
          end

          # Count visible significant cells for visibility calculation
          significant_cells += 1 if pattern_cell == 'o'

          # Set segment value based on radar
          segment[row_offset][col_offset] = @radar.grid[grid_row][grid_col] == 'o' ? 1 : 0
          visible_cells += 1
        end
      end

      [segment, significant_cells]
    end

    # Calculate mean of a numeric matrix
    def calculate_mean(matrix)
      sum = 0
      count = 0

      matrix.each do |row|
        row.each do |value|
          sum += value
          count += 1
        end
      end

      count.zero? ? 0 : sum.to_f / count
    end

    # Calculate standard deviation of a numeric matrix
    def calculate_std(matrix, mean)
      sum_squared_diff = 0
      count = 0

      matrix.each do |row|
        row.each do |value|
          sum_squared_diff += (value - mean)**2
          count += 1
        end
      end

      return 1.0 if count <= 1 # Avoid division by zero or negative sqrt

      Math.sqrt(sum_squared_diff / (count - 1))
    end

    # Calculate normalized cross-correlation between pattern and radar segment
    def calculate_correlation(pattern, radar, pattern_mean, radar_mean, pattern_std, radar_std)
      # Avoid division by zero
      return 0.0 if pattern_std.zero? || radar_std.zero?

      sum_product = 0
      count = 0

      pattern.each_with_index do |row, i|
        row.each_with_index do |pattern_value, j|
          radar_value = radar[i][j]

          # Normalize values
          norm_pattern = (pattern_value - pattern_mean) / pattern_std
          norm_radar = (radar_value - radar_mean) / radar_std

          # Sum of products of normalized values
          sum_product += norm_pattern * norm_radar
          count += 1
        end
      end

      # Correlation coefficient
      count.zero? ? 0 : sum_product / count
    end

    # Count matching cells for reference
    def count_matching_cells(invader, start_row, start_col)
      matching_cells = 0

      invader.pattern.each_with_index do |pattern_row, row_offset|
        pattern_row.each_with_index do |pattern_cell, col_offset|
          grid_row = start_row + row_offset
          grid_col = start_col + col_offset

          # Skip if outside radar bounds
          next unless within_radar_bounds?(grid_row, grid_col)

          # Only count 'o' cells in the pattern as significant
          next unless pattern_cell == 'o'

          grid_cell = @radar.grid[grid_row][grid_col]
          matching_cells += 1 if grid_cell == pattern_cell
        end
      end

      matching_cells
    end
  end
end
