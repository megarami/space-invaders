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
      cyan: "\e[36m",
    }.freeze

    def initialize(radar, matches, format = nil)
      @radar = radar
      @matches = matches
      @format = format || Configuration::DEFAULTS[:output_format]
      @color_enabled = @format == 'text' && $stdout.tty?
      @invader_colors = generate_invader_colors
    end

    def generate_invader_colors
      # Get all invader types from the SpaceInvaders module
      invader_types = SpaceInvaders.constants
                                   .map { |const| SpaceInvaders.const_get(const) }
                                   .select { |const| const.is_a?(Class) && const < Invader && const != Invader } # rubocop:disable Layout/LineLength
                                   .map do |klass|
        klass.name.split('::').last.gsub(/Invader$/,
                                         '').downcase
      end

      # Available colors (excluding reset, which is not a display color)
      available_colors = COLORS.keys - [:reset]

      # Map each invader type to a color
      colors = {}

      invader_types.each_with_index do |type, index|
        # Cycle through available colors if we have more invader types than colors
        color = available_colors[index % available_colors.size]
        colors[type] = color
      end

      colors
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

      "#{legend}#{grid.map(&:join).join("\n")}\n#{match_data}"
    end

    def visualize_full_radar
      # Create a copy of the radar grid
      visualization = @radar.grid.map(&:dup)

      # Mark each detected invader
      @matches.each do |match|
        mark_invader(visualization, match)
      end

      # Add legend
      legend = create_legend

      # Convert to string
      result = "#{legend}\n\n"

      # Format the visualization - same for both ascii and text formats
      result + visualization.map(&:join).join("\n")
    end

    def create_legend
      return '' unless @color_enabled

      legend = "Legend:\n"

      if @format == 'text'
        # Add all detected invader types to the legend
        detected_types = @matches.map { |match| match[:invader].name.downcase }.uniq

        detected_types.each do |type|
          color = get_color_for_invader_type(type)
          legend += "#{colorize('O', color)} = #{type.capitalize} Invader\n"
        end
      else
        # Legend for individual match visualization
        legend += "#{colorize('o', :green)} = Matching invader pattern\n"
        legend += "#{colorize('x', :red)} = Missing pattern cell\n"
        legend += "#{colorize('?', :yellow)} = Radar noise\n"
      end

      legend
    end

    private

    def mark_invader(grid, match)
      invader = match[:invader]
      start_row, start_col = match[:position]

      # Get color for this invader type
      invader_color = get_color_for_invader_type(invader.name.downcase)

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
      @invader_colors[type] || @invader_colors['default']
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
