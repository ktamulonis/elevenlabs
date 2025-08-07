# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "elevenlabs"
  spec.version       = "0.0.5"
  spec.authors       = ["hackliteracy"]
  spec.email         = ["hackliteracy@gmail.com"]
  spec.summary       = %q{A Ruby client for the ElevenLabs Text-to-Speech API}
  spec.description   = %q{This gem provides a convenient Ruby interface to the ElevenLabs TTS, Voice Cloning, Voice Design and Streaming endpoints.}
  spec.homepage      = "https://github.com/ktamulonis/elevenlabs" 
  spec.license       = "MIT"
  spec.files         = Dir["lib/**/*", "README.md"]
  
  spec.required_ruby_version = ">= 2.5"

  spec.add_dependency "faraday", "~> 2.0"
  spec.add_dependency "faraday-multipart", "~> 1.1"
  spec.metadata["source_code_uri"] = 'https://github.com/ktamulonis/elevenlabs'
end

