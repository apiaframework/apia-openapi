# frozen_string_literal: true

module CoreAPI
  module Endpoints
    class PlainTextEndpoint < Apia::Endpoint
      name "Plain Text Endpoint"
      description "Return a plain text response"
      response_type Apia::Response::PLAIN

      def call
        response.body = "hello world!"
      end

    end
  end
end
