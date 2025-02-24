# Elevenlabs Ruby Gem

[![Gem Version](https://badge.fury.io/rb/elevenlabs.svg)](https://badge.fury.io/rb/elevenlabs)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)

A **Ruby client** for the [ElevenLabs](https://elevenlabs.io/) **Text-to-Speech API**.  
This gem provides an easy-to-use interface for:

- **Listing available voices**
- **Fetching details about a voice**
- **Creating a custom voice** (with uploaded sample files)
- **Editing an existing voice**
- **Deleting a voice**
- **Converting text to speech** and retrieving the generated audio

All requests are handled via [Faraday](https://github.com/lostisland/faraday).

---

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
  - [Basic Example](#basic-example)
  - [Rails Integration](#rails-integration)
    - [Store API Key in Rails Credentials](#store-api-key-in-rails-credentials)
    - [Rails Initializer](#rails-initializer)
    - [Controller Example](#controller-example)
- [Endpoints](#endpoints)
- [Error Handling](#error-handling)
- [Development](#development)
- [Contributing](#contributing)
- [License](#license)

---

## Features

- **Simple and intuitive API client** for ElevenLabs.
- **Multipart file uploads** for training custom voices.
- **Automatic authentication** via API key configuration.
- **Error handling** with custom exceptions.
- **Rails integration support** (including credentials storage).

---

## Installation

Add the gem to your `Gemfile`:

```ruby
gem "elevenlabs"
```
Then run:
```ruby
bundle install
```
Or install it directly using:
```ruby
gem install elevenlabs
```
Usage
Basic Example (Standalone Ruby)
```ruby
require "elevenlabs"

# 1. Configure the gem globally (Optional)
Elevenlabs.configure do |config|
  config.api_key = "YOUR_API_KEY"
end

# 2. Initialize a client (will use configured API key)
client = Elevenlabs::Client.new

# 3. List available voices
voices = client.list_voices
puts voices # JSON response with voices

# 4. Convert text to speech
voice_id = "YOUR_VOICE_ID"
text = "Hello from Elevenlabs!"
audio_data = client.text_to_speech(voice_id, text)

# 5. Save the audio file
File.open("output.mp3", "wb") { |f| f.write(audio_data) }
puts "Audio file saved to output.mp3"
```
Note: You can override the API key per request:
```ruby
client = Elevenlabs::Client.new(api_key: "DIFFERENT_API_KEY")
```
Rails Integration
Store API Key in Rails Credentials
1. Open your encrypted credentials:
```ruby
EDITOR=vim rails credentials:edit
```

2. Add the ElevenLabs API key:
```ruby
eleven_labs:
  api_key: YOUR_SECURE_KEY
```
3. Save and exit. Rails will securely encrypt your API key.

Rails Initializer
Create an initializer file: config/initializers/elevenlabs.rb
```ruby
# config/initializers/elevenlabs.rb
require "elevenlabs"

Rails.application.config.to_prepare do
  Elevenlabs.configure do |config|
    config.api_key = Rails.application.credentials.dig(:eleven_labs, :api_key)
  end
end
```
Now you can simply call:
```ruby
client = Elevenlabs::Client.new
```
without manually providing an API key.

Endpoints
1. List Voices
```ruby
client.list_voices
# => { "voices" => [...] }
```
2. Get Voice Details
```ruby
client.get_voice("VOICE_ID")
# => { "voice_id" => "...", "name" => "...", ... }
```
3. Create a Custom Voice
```ruby
sample_files = [File.open("sample1.mp3", "rb")]
client.create_voice("Custom Voice", sample_files, description: "My custom AI voice")
# => JSON response with new voice details
```
4. Check if a voice is banned?
```ruby
sample_files = [File.open("trump.mp3", "rb")]
client.create_voice("Donald Trump", sample_files, description: "My Trump Voice")
  => {"voice_id"=>"<RETURNED_VOICE_ID>", "requires_verification"=>false}
  trump= "<RETURNED_VOICE_ID>"
  client.banned? trump
=> true
```
5. Edit a Voice
```ruby
client.edit_voice("VOICE_ID", name: "Updated Voice Name")
# => JSON response with updated details
```
6. Delete a Voice
```ruby
client.delete_voice("VOICE_ID")
# => JSON response acknowledging deletion
```
7. Convert Text to Speech
```ruby
audio_data = client.text_to_speech("VOICE_ID", "Hello world!")
File.open("output.mp3", "wb") { |f| f.write(audio_data) }
```
8 Stream Text to Speech
stream from terminal
```ruby
Mac: brew install sox
Linux: sudo apt install sox

IO.popen("play -t mp3 -", "wb") do |audio_pipe| # Notice "wb" (write binary)
  client.text_to_speech_stream("VOICE_ID", "Some text to stream back in chunks") do |chunk|
    audio_pipe.write(chunk.b) # Ensure chunk is written as binary
  end
end
```

Error Handling
When the API returns an error, the gem raises specific exceptions:

Exception	Meaning
Elevenlabs::BadRequestError	Invalid request parameters
Elevenlabs::AuthenticationError	Invalid API key
Elevenlabs::NotFoundError	Resource (voice) not found
Elevenlabs::APIError	General API failure
Example:

```ruby
begin
  client.text_to_speech("INVALID_VOICE_ID", "Test")
rescue Elevenlabs::AuthenticationError => e
  puts "Invalid API key: #{e.message}"
rescue Elevenlabs::NotFoundError => e
  puts "Voice not found: #{e.message}"
rescue Elevenlabs::APIError => e
  puts "General error: #{e.message}"
end
```

Development
Clone this repository
```bash
git clone https://github.com/your-username/elevenlabs.git
cd elevenlabs
```
Install dependencies
```bash
bundle install
```
Build the gem
```bash
gem build elevenlabs.gemspec
```
Install the gem locally
```bash
gem install ./elevenlabs-0.0.3.gem
```
Contributing
Contributions are welcome! Please follow these steps:

Fork the repository
Create a feature branch (git checkout -b feature/my-new-feature)
Commit your changes (git commit -am 'Add new feature')
Push to your branch (git push origin feature/my-new-feature)
Create a Pull Request describing your changes
For bug reports, please open an issue with details.

License
This project is licensed under the MIT License. See the LICENSE file for details.

⭐ Thank you for using the Elevenlabs Ruby Gem!
If you have any questions or suggestions, feel free to open an issue or submit a Pull Request!

# elevenlabs
