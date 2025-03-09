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
      @invaders = []

      @invaders << LargeInvader if @config.invader_types.include?('large')

      @invaders << SmallInvader if @config.invader_types.include?('small')

      return unless @invaders.empty?

      raise(ArgumentError, "No valid invader types specified. Must include 'large' and/or 'small'.")
    end
  end
end
