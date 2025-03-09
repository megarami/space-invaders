# frozen_string_literal: true

module SpaceInvaders
  # Configuration class to manage detection parameters
  class Configuration
    # Default configuration values
    DEFAULTS = {
      # Minimum similarity threshold for considering a match
      min_similarity: 0.7,

      # Minimum percentage of pattern that must be visible
      min_visibility: 0.5,

      # Maximum percentage to consider matches as duplicates
      duplicate_threshold: 0.3,

      # Output format (text or ascii)
      output_format: 'text',

      # Output visualization settings
      visualization: true,

      # Invader types to detect
      invader_types: %w[large small]
    }.freeze

    DEFAULTS.each_key do |key|
      attr_accessor key
    end

    def initialize(options = {})
      DEFAULTS.each do |key, value|
        instance_variable_set("@#{key}", options.fetch(key, value))
      end

      validate!
    end

    def merge(options)
      current_values = to_h.merge(options)
      self.class.new(current_values)
    end

    def to_h
      DEFAULTS.keys.each_with_object({}) do |key, hash|
        hash[key] = send(key)
      end
    end

    private

    def validate!
      validate_range(:min_similarity, 0.0..1.0)
      validate_range(:min_visibility, 0.0..1.0)
      validate_range(:duplicate_threshold, 0.0..1.0)
      validate_array(:invader_types)
      validate_inclusion(:output_format, %w[text ascii])
    end

    def validate_range(attribute, range)
      value = send(attribute)
      return if range.include?(value)

      raise(ArgumentError, "#{attribute} must be between #{range.min} and #{range.max}")
    end

    def validate_array(attribute)
      value = send(attribute)
      raise(ArgumentError, "#{attribute} must be an array") unless value.is_a?(Array)
      raise(ArgumentError, "#{attribute} cannot be empty") if value.empty?
    end

    def validate_inclusion(attribute, allowed_values)
      value = send(attribute)
      return if allowed_values.include?(value)

      raise(ArgumentError, "#{attribute} must be one of: #{allowed_values.join(', ')}")
    end
  end
end
