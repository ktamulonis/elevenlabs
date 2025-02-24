# lib/elevenlabs.rb
# frozen_string_literal: true

require_relative "elevenlabs/client"
require_relative "elevenlabs/errors"

module Elevenlabs
  VERSION = "0.0.1"

  # Optional global configuration
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  class Configuration
    attr_accessor :api_key
  end
end

