# frozen_string_literal: true

module SpaceInvaders
  # Service class to coordinate the invader detection process
  class DetectorService
    attr_reader :radar, :invaders

    def initialize(radar_data, config = Configuration.new)
      @radar = Radar.new(radar_data)
      @config = config
      load_invaders
    end

    def detect
      detector = Detector.new(@radar, @invaders, @config)
      detector.detect
    end

    private

    def load_invaders
      all_invaders = InvaderLoader.load_invaders

      # Filter invaders based on configuration
      @invaders = if @config.invader_types.include?('all')
                    all_invaders
                  else
                    all_invaders.select do |invader|
                      type_name = invader.name.downcase
                      @config.invader_types.include?(type_name)
                    end
                  end

      return unless @invaders.empty?

      available_types = all_invaders.map { |i| i.name.downcase }.join(', ')
      raise(ArgumentError,
            "No valid invader types specified. Available types: #{available_types}, all")
    end
  end
end
