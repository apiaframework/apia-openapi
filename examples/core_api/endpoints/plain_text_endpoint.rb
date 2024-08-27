# frozen_string_literal: true

require "core_api/argument_sets/key_value"


module CoreAPI
  module Endpoints
    class PlainTextEndpoint < Apia::Endpoint

      name "Plain Text Endpoint"
      description "Return a plain text response"
      argument :disk_template_options, [CoreAPI::ArgumentSets::KeyValue], required: false


      response_type Apia::Response::PLAIN

      def call
        response.body = "hello world!"
      end

    end
  end
end
