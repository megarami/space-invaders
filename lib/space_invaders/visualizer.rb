# frozen_string_literal: true

module SpaceInvaders
  # Visualizer class to render detected invaders in the radar
  class Visualizer
    COLORS = {
      reset: "\e[0m",
      red: "\e[31m",
      green: "\e[32m",
      yellow: "\e[33m",
      blue: "\e[34m",
      magenta: "\e[35m",
      cyan: "\e[36m"
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

      legend = ''
      if @color_enabled
        legend = "Legend:\n"
        legend += "#{colorize('o', :green)} = Matching invader pattern\n"
        legend += "#{colorize('x', :red)} = Missing pattern cell\n"
        legend += "#{colorize('?', :yellow)} = Radar noise\n"
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
      match_data += "Match similarity: #{(match[:similarity] * 100).round(2)}%\n\n"

      legend + grid.map(&:join).join("\n") + "\n" + match_data
    end

    def visualize_full_radar
      # Create a copy of the radar grid
      visualization = @radar.grid.map(&:dup)

      # Mark each detected invader
      @matches.each do |match|
        mark_invader(visualization, match, nil) # Color will be determined by invader type
      end

      # Add legend
      legend = create_legend

      # Convert to string
      result = legend + "\n\n"

      if @format == 'ascii'
        result + visualization.map { |row| row.join }.join("\n")
      else
        result + visualization.map { |row| row.join }.join("\n")
      end
    end

    def create_legend
      return '' unless @color_enabled

      legend = "Legend:\n"

      if @format == 'text'
        # Add specific colors for each invader type
        legend += "#{colorize('O', :cyan)} = Large Invader\n"
        legend += "#{colorize('O', :magenta)} = Small Invader\n"

      else
        # Legend for individual match visualization
        legend += "#{colorize('o', :green)} = Matching invader pattern\n"
        legend += "#{colorize('x', :red)} = Missing pattern cell\n"
        legend += "#{colorize('?', :yellow)} = Radar noise\n"
      end

      legend
    end

    private

    def mark_invader(grid, match, _color)
      invader = match[:invader]
      start_row, start_col = match[:position]

      # Map invader type to specific color
      invader_type = invader.name.split('::').last
      invader_color = get_color_for_invader_type(invader_type)

      # Mark the actual invader cells
      invader.pattern.each_with_index do |pattern_row, row_idx|
        pattern_row.each_with_index do |cell, col_idx|
          radar_row = start_row + row_idx
          radar_col = start_col + col_idx

          next unless within_radar_bounds?(radar_row, radar_col)
          next unless cell == 'o'

          grid[radar_row][radar_col] = colorize('o', invader_color)
        end
      end
    end

    def get_color_for_invader_type(type)
      # Map invader types to specific colors
      case type
      when 'LargeInvader'
        :cyan
      when 'SmallInvader'
        :magenta
      else
        # For any new invader types, use a default color
        :blue
      end
    end

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
