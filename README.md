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
- **Designing a voice** based on a text description
- **Streaming text-to-speech audio**

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
- **Voice design** via text prompts to generate voice previews.
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

```bash
bundle install
```

Or install it directly using:

```bash
gem install elevenlabs
```

---

## Usage

### Basic Example (Standalone Ruby)

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

# 6. Design a voice with a text prompt
response = client.design_voice(
  "A deep, resonant male voice with a British accent, suitable for storytelling",
  output_format: "mp3_44100_192",
  model_id: "eleven_multilingual_ttv_v2",
  text: "In a land far away, where the mountains meet the sky, a great adventure began. Brave heroes embarked on a quest to find the lost artifact, facing challenges and forging bonds that would last a lifetime. Their journey took them through enchanted forests, across raging rivers, and into the heart of ancient ruins.",
  auto_generate_text: false,
  loudness: 0.5,
  seed: 12345,
  guidance_scale: 5.0,
  stream_previews: false
)

# 7. Save voice preview audio
require "base64"
response["previews"].each_with_index do |preview, index|
  audio_data = Base64.decode64(preview["audio_base_64"])
  File.open("preview_#{index}.mp3", "wb") { |f| f.write(audio_data) }
  puts "Saved preview #{index + 1} to preview_#{index}.mp3"
end
```

Note: You can override the API key per request:

```ruby
client = Elevenlabs::Client.new(api_key: "DIFFERENT_API_KEY")
```

### Rails Integration

#### Store API Key in Rails Credentials

1. Open your encrypted credentials:

```bash
EDITOR=vim rails credentials:edit
```

2. Add the ElevenLabs API key:

```yaml
eleven_labs:
  api_key: YOUR_SECURE_KEY
```

3. Save and exit. Rails will securely encrypt your API key.

#### Rails Initializer

Create an initializer file: `config/initializers/elevenlabs.rb`

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

#### Controller Example

```ruby
class AudioController < ApplicationController
  def generate
    client = Elevenlabs::Client.new
    voice_id = params[:voice_id]
    text = params[:text]

    begin
      audio_data = client.text_to_speech(voice_id, text)
      send_data audio_data, type: "audio/mpeg", disposition: "attachment", filename: "output.mp3"
    rescue Elevenlabs::APIError => e
      render json: { error: e.message }, status: :bad_request
    end
  end
end
```

---

## Endpoints

1. **List Voices**

```ruby
client.list_voices
# => { "voices" => [...] }

2. List Models

client.list_models
# => [...]

3. **Get Voice Details**

```ruby
client.get_voice("VOICE_ID")
# => { "voice_id" => "...", "name" => "...", ... }
```

4. **Create a Custom Voice**

```ruby
sample_files = [File.open("sample1.mp3", "rb")]
client.create_voice("Custom Voice", sample_files, description: "My custom AI voice")
# => JSON response with new voice details
```

5. **Check if a Voice is Banned**

```ruby
sample_files = [File.open("trump.mp3", "rb")]
client.create_voice("Donald Trump", sample_files, description: "My Trump Voice")
# => {"voice_id"=>"<RETURNED_VOICE_ID>", "requires_verification"=>false}
trump = "<RETURNED_VOICE_ID>"
client.banned?(trump)
# => true
```

6. **Edit a Voice**

```ruby
client.edit_voice("VOICE_ID", name: "Updated Voice Name")
# => JSON response with updated details
```

7. **Delete a Voice**

```ruby
client.delete_voice("VOICE_ID")
# => JSON response acknowledging deletion
```

8. **Convert Text to Speech**

```ruby
audio_data = client.text_to_speech("VOICE_ID", "Hello world!")
File.open("output.mp3", "wb") { |f| f.write(audio_data) }
```

9. **Stream Text to Speech**

Stream from terminal:

```bash
# Mac: Install sox
brew install sox
# Linux: Install sox
sudo apt install sox
```

```ruby
IO.popen("play -t mp3 -", "wb") do |audio_pipe| # Notice "wb" (write binary)
  client.text_to_speech_stream("VOICE_ID", "Some text to stream back in chunks") do |chunk|
    audio_pipe.write(chunk.b) # Ensure chunk is written as binary
  end
end
```

10. **Create a Voice from a Design**

Once you’ve generated a voice design using client.design_voice, you can turn it into a permanent voice in your account by passing its generated_voice_id to client.create_from_generated_voice.

# Step 1: Design a voice (returns previews + generated_voice_id)
```ruby
design_response = client.design_voice(
  "A warm, friendly female voice with a slight Australian accent",
  model_id: "eleven_multilingual_ttv_v2",
  text: "Welcome to our podcast, where every story is an adventure, taking you on a journey through fascinating worlds, inspiring voices, and unforgettable moments.",
  auto_generate_text: false
)

generated_voice_id = design_response["previews"].first["generated_voice_id"] #three previews are given, but for this example we will use the first to create a voice here

# Step 2: Create the permanent voice
create_response = client.create_from_generated_voice(
  "Friendly Aussie",
  "A warm, friendly Australian-accented voice for podcasts",
   generated_voice_id,
)

voice_id = create_response["voice_id"] # This is the ID you can use for TTS

# Step 3: Use the new voice for TTS
audio_data = client.text_to_speech(voice_id, "This is my new permanent designed voice.")
File.open("friendly_aussie.mp3", "wb") { |f| f.write(audio_data) }
```
Important notes:

Always store the returned voice_id from create_voice_from_design. This is the permanent identifier for TTS.

Designed voices cannot be used for TTS until they are created in your account.

If the voice is not immediately available for TTS, wait a few seconds or check its status via client.get_voice(voice_id) until it’s "active".

10. Create a multi-speaker dialogue
```ruby
inputs = [{text: "It smells like updog in here", voice_id: "TX3LPaxmHKxFdv7VOQHJ"}, {text: "What's updog?", voice_id: "RILOU7YmBhvwJGDGjNmP"}, {text: "Not much, you?", voice_id: "TX3LPaxmHKxFdv7VOQHJ"}]

audio_data = client.text_to_dialogue(inputs)
File.open("what's updog.mp3", "wb") { |f| f.write(audio_data) }
```

---

## Error Handling

When the API returns an error, the gem raises specific exceptions:

| Exception                     | Meaning                          |
|-------------------------------|----------------------------------|
| `Elevenlabs::BadRequestError` | Invalid request parameters       |
| `Elevenlabs::AuthenticationError` | Invalid API key              |
| `Elevenlabs::NotFoundError`   | Resource (voice) not found       |
| `Elevenlabs::UnprocessableEntityError` | Unprocessable entity (e.g., invalid input format) |
| `Elevenlabs::APIError`        | General API failure              |

Example:

```ruby
begin
  client.design_voice("Short description") # Too short, will raise error
rescue Elevenlabs::UnprocessableEntityError => e
  puts "Validation error: #{e.message}"
rescue Elevenlabs::AuthenticationError => e
  puts "Invalid API key: #{e.message}"
rescue Elevenlabs::NotFoundError => e
  puts "Voice not found: #{e.message}"
rescue Elevenlabs::APIError => e
  puts "General error: #{e.message}"
end
```

---

## Development

Clone this repository:

```bash
git clone https://github.com/your-username/elevenlabs.git
cd elevenlabs
```

Install dependencies:

```bash
bundle install
```

Build the gem:

```bash
gem build elevenlabs.gemspec
```

Install the gem locally:

```bash
gem install ./elevenlabs-0.0.6.gem
```

---

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-new-feature`)
3. Commit your changes (`git commit -am 'Add new feature'`)
4. Push to your branch (`git push origin feature/my-new-feature`)
5. Create a Pull Request describing your changes

For bug reports, please open an issue with details.

---

## License

This project is licensed under the MIT License. See the LICENSE file for details.

⭐ Thank you for using the Elevenlabs Ruby Gem!  
If you have any questions or suggestions, feel free to open an issue or submit a Pull Request!
