# frozen_string_literal: true

# First load base models
require_relative 'space_invaders/models/invader'
require_relative 'space_invaders/models/radar'

# Configuration
require_relative 'space_invaders/config/configuration'

# Algorithm framework
require_relative 'space_invaders/algorithms/detection_algorithm'
require_relative 'space_invaders/algorithms/algorithm_registry'

# Specific algorithms
require_relative 'space_invaders/algorithms/naive_detection_algorithm'
require_relative 'space_invaders/algorithms/cross_correlation_algorithm'
require_relative 'space_invaders/algorithms/block_scanning_algorithm'

# Services
require_relative 'space_invaders/services/detector_service'

# UI
require_relative 'space_invaders/ui/visualizer'

module SpaceInvaders
  VERSION = '1.1.0'

  # Register available algorithms
  AlgorithmRegistry.register('naive', NaiveDetectionAlgorithm)
  AlgorithmRegistry.register('cross', NaiveDetectionAlgorithm)
  AlgorithmRegistry.register('block', NaiveDetectionAlgorithm)
end
