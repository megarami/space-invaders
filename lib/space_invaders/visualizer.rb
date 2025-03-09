# frozen_string_literal: true

module SpaceInvaders
  # Visualizer class to render detected invaders in the radar
  class Visualizer
    COLORS = {
      reset: "\e[0m",
      red: "\e[31m",
      green: "\e[32m",
      yellow: "\e[33m",
    }.freeze

    def initialize(radar, matches, format = 'text')
      @radar = radar
      @matches = matches
      @format = format
      @color_enabled = format == 'text' && $stdout.tty?
    end

    def visualize_match(match)
      invader = match[:invader]
      start_row, start_col = match[:position]

      # Create a local grid for this match
      display_height = invader.height + 4
      display_width = invader.width + 4

      grid = Array.new(display_height) { Array.new(display_width, ' ') }

      # Add a border
      display_height.times do |i|
        grid[i][0] = '|'
        grid[i][display_width - 1] = '|'
      end

      display_width.times do |j|
        grid[0][j] = '-'
        grid[display_height - 1][j] = '-'
      end

      # Add the invader pattern
      invader.pattern.each_with_index do |pattern_row, row_idx|
        pattern_row.each_with_index do |cell, col_idx|
          radar_row = start_row + row_idx
          radar_col = start_col + col_idx

          next unless within_radar_bounds?(radar_row, radar_col)

          grid_row = row_idx + 2
          grid_col = col_idx + 2

          radar_cell = @radar.grid[radar_row][radar_col]

          grid[grid_row][grid_col] = if cell == 'o'
                                       if radar_cell == 'o'
                                         colorize('o', :green)
                                       else
                                         colorize('x', :red)
                                       end
                                     elsif radar_cell == 'o'
                                       colorize('?', :yellow)
                                     else
                                       ' '
                                     end
        end
      end

      match_data = "Invader: #{invader.name}\n"
      match_data += "Position: (#{start_row}, #{start_col})\n"
      match_data += "Match confidence: #{match[:confidence]}%\n\n"

      match_data + grid.map(&:join).join("\n")
    end

    private

    def within_radar_bounds?(row, col)
      row >= 0 && row < @radar.height && col >= 0 && col < @radar.width
    end

    def colorize(text, color)
      return text unless @color_enabled
      return text unless COLORS.key?(color)

      "#{COLORS[color]}#{text}#{COLORS[:reset]}"
    end
  end
end