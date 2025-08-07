# frozen_string_literal: true

module Elevenlabs
  class Error < StandardError; end
  class APIError < Error; end
  class AuthenticationError < Error; end
  class NotFoundError < Error; end
  class BadRequestError < Error; end
  class UnprocessableEntityError < Error; end
end

