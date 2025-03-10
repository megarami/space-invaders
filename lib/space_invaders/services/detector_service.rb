# frozen_string_literal: true

module SpaceInvaders
  # Service class to coordinate the invader detection process
  class DetectorService
    attr_reader :radar, :invaders

    def initialize(radar_data, config = Configuration.new)
      @radar = Radar.new(radar_data)
      @config = config
      @invaders = InvaderLoader.load_invaders(@config)
    end

    def detect
      algorithm_class = AlgorithmRegistry.get(@config.algorithm)

      unless algorithm_class
        available = AlgorithmRegistry.available_algorithms.join(', ')
        raise(ArgumentError,
              "Unknown algorithm '#{@config.algorithm}'. Available algorithms: #{available}")
      end

      algorithm = algorithm_class.new(@radar, @invaders, @config)

      # Run the detection
      algorithm.detect
    end
  end
end
