# frozen_string_literal: true

module SpaceInvaders
  # Service class to coordinate the invader detection process
  class DetectorService
    attr_reader :radar, :invaders

    def initialize(radar_data, config = {})
      @radar = Radar.new(radar_data)
      @config = {
        min_similarity: 0.7,
        invader_types: %w[large small]
      }.merge(config)

      load_invaders
    end

    def detect
      detector = Detector.new(@radar, @invaders)
      detector.detect(@config[:min_similarity])
    end

    private

    def load_invaders
      @invaders = []

      @invaders << LargeInvader if @config[:invader_types].include?('large')

      @invaders << SmallInvader if @config[:invader_types].include?('small')

      return unless @invaders.empty?

      raise(ArgumentError, "No valid invader types specified. Must include 'large' and/or 'small'.")
    end
  end
end
