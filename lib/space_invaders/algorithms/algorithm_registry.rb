# frozen_string_literal: true

module SpaceInvaders
  # Registry for detection algorithms
  class AlgorithmRegistry
    class << self
      def algorithms
        @algorithms ||= {}
      end

      def register(name, algorithm_class)
        algorithms[name.to_s] = algorithm_class
      end

      def get(name)
        algorithms[name.to_s]
      end

      def available_algorithms
        algorithms.keys
      end
    end
  end
end
