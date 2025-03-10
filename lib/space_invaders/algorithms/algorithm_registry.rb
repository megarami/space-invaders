# frozen_string_literal: true

module SpaceInvaders
  # Registry for detection algorithms
  class AlgorithmRegistry
    # Map of algorithm names to their classes
    @@algorithms = {}

    class << self
      # Register a new algorithm
      def register(name, algorithm_class)
        @@algorithms[name.to_s] = algorithm_class
      end

      # Get an algorithm class by name
      def get(name)
        @@algorithms[name.to_s]
      end

      # Get the list of available algorithm names
      def available_algorithms
        @@algorithms.keys
      end
    end
  end
end
