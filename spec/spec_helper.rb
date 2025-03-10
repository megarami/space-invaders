# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
end

# Load the main application
require_relative '../lib/space_invaders'

# Special testing configurations
require 'fileutils'
require 'tempfile'

# Configure RSpec
RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with(:rspec) do |c|
    c.syntax = :expect
  end

  # Exit the spec after the first failure
  # config.fail_fast = true

  # Use the specified formatter
  config.formatter = :documentation
end
