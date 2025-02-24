# frozen_string_literal: true

require "faraday"
require "faraday/multipart"
require "json"

module Elevenlabs
  class Client
    BASE_URL = "https://api.elevenlabs.io"

    # Note the default param: `api_key: nil`
    def initialize(api_key: nil)
      # If the caller doesn’t provide an api_key, use the gem-wide config
      @api_key = api_key || Elevenlabs.configuration&.api_key

      @connection = Faraday.new(url: BASE_URL) do |conn|
        conn.request :url_encoded
        conn.response :raise_error
        conn.adapter Faraday.default_adapter
      end
    end

    #####################################################
    #                     Text-to-Speech                #
    #    (POST /v1/text-to-speech/{voice_id})           #
    #####################################################

    # Convert text to speech and retrieve audio (binary data)
    # Documentation: https://elevenlabs.io/docs/api-reference/text-to-speech/convert
    #
    # @param [String] voice_id - the ID of the voice to use
    # @param [String] text - text to synthesize
    # @param [Hash] options - optional TTS parameters
    #   :model_id           => String   (e.g. "eleven_monolingual_v1" or "eleven_multilingual_v1")
    #   :voice_settings     => Hash     (stability, similarity_boost, style, use_speaker_boost, etc.)
    #   :optimize_streaming => Boolean  (whether to receive chunked streaming audio)
    #
    # @return [String] The binary audio data (usually an MP3).
    def text_to_speech(voice_id, text, options = {})
      endpoint = "/v1/text-to-speech/#{voice_id}"
      request_body = { text: text }

      # If user provided voice_settings, add them
      if options[:voice_settings]
        request_body[:voice_settings] = options[:voice_settings]
      end

      # If user specified a model_id, add it
      request_body[:model_id] = options[:model_id] if options[:model_id]

      # If user wants streaming optimization
      headers = default_headers
      if options[:optimize_streaming]
        headers["Accept"] = "audio/mpeg"
        headers["Transfer-Encoding"] = "chunked"
      end

      response = @connection.post(endpoint) do |req|
        req.headers = headers
        req.body = request_body.to_json
      end

      # Returns raw binary data (often MP3)
      response.body
    rescue Faraday::ClientError => e
      handle_error(e)
    end

    #####################################################
    #              Text-to-Speech-Stream                #
    # (POST /v1/text-to-speech/{voice_id})/stream       #
    #####################################################
    def text_to_speech_stream(voice_id, text, options = {}, &block)
      endpoint = "/v1/text-to-speech/#{voice_id}/stream?output_format=mp3_44100_128"
      request_body = { text: text, model_id: options[:model_id] || "eleven_multilingual_v2" }

      headers = default_headers
      headers["Accept"] = "audio/mpeg"

      response = @connection.post(endpoint, request_body.to_json, headers) do |req|
        req.options.on_data = Proc.new do |chunk, _|
          block.call(chunk) if block_given?
        end
      end

      response
    rescue Faraday::ClientError => e
      handle_error(e)
    end


    #####################################################
    #                     GET Voices                    #
    #                  (GET /v1/voices)                 #
    #####################################################

    # Retrieves all voices associated with your Elevenlabs account
    # Documentation: https://elevenlabs.io/docs/api-reference/voices
    #
    # @return [Hash] The JSON response containing an array of voices
    def list_voices
      endpoint = "/v1/voices"
      response = @connection.get(endpoint) do |req|
        req.headers = default_headers
      end
      JSON.parse(response.body)
    rescue Faraday::ClientError => e
      handle_error(e)
    end

    #####################################################
    #                 GET a Single Voice                #
    #               (GET /v1/voices/{voice_id})         #
    #####################################################

    # Retrieves details about a single voice
    #
    # @param [String] voice_id
    # @return [Hash] Details of the voice
    def get_voice(voice_id)
      endpoint = "/v1/voices/#{voice_id}"
      response = @connection.get(endpoint) do |req|
        req.headers = default_headers
      end
      JSON.parse(response.body)
    rescue Faraday::ClientError => e
      handle_error(e)
    end

    #####################################################
    #                Create a Voice                     #
    #               (POST /v1/voices/add)               #
    #####################################################

    # Creates a new voice
    # @param [String] name - name of the voice
    # @param [File] samples - array of files to train the voice
    # @param [Hash] options - additional parameters
    #   :description => String
    #
    # NOTE: This method may require a multipart form request
    #       if you are uploading sample audio files.
    def create_voice(name, samples = [], options = {})
      endpoint = "/v1/voices/add"

      # Ensure Faraday handles multipart form data
      mp_connection = Faraday.new(url: BASE_URL) do |conn|
        conn.request :multipart
        conn.response :raise_error
        conn.adapter Faraday.default_adapter
      end

      # Build multipart form parameters
      form_params = {
        "name" => name,
        "description" => options[:description] || ""
      }

      # Convert File objects to multipart upload format
      sample_files = []
      samples.each_with_index do |sample_file, i|
        sample_files << ["files", Faraday::UploadIO.new(sample_file.path, "audio/mpeg")]
      end

      # Perform the POST request
      response = mp_connection.post(endpoint) do |req|
        req.headers["xi-api-key"] = @api_key
        req.body = form_params.merge(sample_files.to_h)
      end

      JSON.parse(response.body)
    rescue Faraday::ClientError => e
      handle_error(e)
    end


    #####################################################
    #                Edit a Voice                       #
    #           (POST /v1/voices/{voice_id}/edit)       #
    #####################################################
    # Updates an existing voice
    # @param [String] voice_id
    # @param [Array<File>] samples
    # @param [Hash] options
    # options[:name] [String] name
    # options[:description] [String] description
     
    def edit_voice(voice_id, samples = [], options = {})
      endpoint = "/v1/voices/#{voice_id}/edit"

      # Force text fields to be strings.
      form_params = {
        "name"        => options[:name].to_s,
        "description" => (options[:description] || "").to_s
      }

      form_params["files[]"] = samples.map do |sample_file|
        Faraday::UploadIO.new(sample_file.path, "audio/mpeg", File.basename(sample_file.path))
      end

      mp_connection = Faraday.new(url: BASE_URL) do |conn|
        conn.request :multipart
        conn.response :raise_error
        conn.adapter Faraday.default_adapter
      end

      response = mp_connection.post(endpoint) do |req|
        req.headers["xi-api-key"] = @api_key
        req.body = form_params
      end

      JSON.parse(response.body)
    rescue Faraday::ClientError => e
      handle_error(e)
    end

    #####################################################
    #                Delete a Voice                     #
    #         (DELETE /v1/voices/{voice_id})            #
    #####################################################

    # Deletes a voice from your account
    # @param [String] voice_id
    # @return [Hash] response
    def delete_voice(voice_id)
      endpoint = "/v1/voices/#{voice_id}"
      response = @connection.delete(endpoint) do |req|
        req.headers = default_headers
      end

      JSON.parse(response.body)
    rescue Faraday::ClientError => e
      handle_error(e)
    end

    #####################################################
    #                 Banned Voice Check                #
    #####################################################
    
    # Checks safety control on a single voice for "BAN"
    # 
    # @param [String] voice_id 
    # @return [Boolean]
    def banned?(voice_id)
      voice = get_voice(voice_id)
      voice["safety_control"] == "BAN"
    end

    #####################################################
    #                 Active Voice Check                #
    #####################################################
    
    # Checks if a voice_id is in list_voices
    #
    # @param [String] voice_id
    # @return [Boolean]
    def active?(voice_id)
      active_voices = list_voices["voices"].map{|voice| voice["voice_id"]}
      voice_id.in?(active_voices)
    end

    private

    # Common headers needed by Elevenlabs
    def default_headers
      {
        "xi-api-key"   => @api_key,
        "Content-Type" => "application/json"
      }
    end

    # Error handling
    def handle_error(exception)
      status = exception.response[:status] rescue nil
      body   = exception.response[:body]   rescue "{}"
      error_info = JSON.parse(body) rescue {}

      detail = error_info["detail"]
      simple_message = detail.is_a?(Hash) ? detail["message"] || detail.to_s : detail.to_s

      case status
      when 400 then raise BadRequestError, simple_message
      when 401 then raise AuthenticationError, simple_message
      when 404 then raise NotFoundError, simple_message
      else
        raise APIError, simple_message
      end
    end
  end
end

