# frozen_string_literal: true

require "core_api/errors/rate_limit_reached"

module CoreAPI
  module Authenticators
    class TimeControllerAuthenticator < Apia::Authenticator

      potential_error CoreAPI::Errors::RateLimitReached

    end
  end
end
