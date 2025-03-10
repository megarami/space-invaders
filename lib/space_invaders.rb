# frozen_string_literal: true

# First load base models
require_relative 'space_invaders/models/invader'
require_relative 'space_invaders/models/radar'

# Configuration
require_relative 'space_invaders/config/configuration'

# Services
require_relative 'space_invaders/services/detector'
require_relative 'space_invaders/services/detector_service'

# UI
require_relative 'space_invaders/ui/visualizer'

module SpaceInvaders
  VERSION = '1.0.0'
end

# Load invader patterns after all classes are defined
SpaceInvaders::InvaderLoader.load_invaders
