# frozen_string_literal: true

module CoreAPI
  module Errors
    class RateLimitReached < Apia::Error

      code :rate_limit_reached
      http_status 429
      description "You have reached the rate limit for this type of request"

      field :total_permitted, type: :integer do
        description "The total number of requests per minute that are permitted"
      end

    end
  end
end
