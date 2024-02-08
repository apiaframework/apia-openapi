# frozen_string_literal: true

module CoreAPI
  module Endpoints
    class LegacyEndpoint < Apia::Endpoint

      description "We don't use this any more"

      field :some_legacy_field, type: :string

      def call
        response.add_field :some_legacy_field, "hello!"
      end

    end
  end
end
