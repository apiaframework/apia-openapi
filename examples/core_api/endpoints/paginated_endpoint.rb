# frozen_string_literal: true

module CoreAPI
  module Endpoints
    class PaginatedEndpoint < Apia::Endpoint

      name "Paginated Endpoint"
      description "Returns a paginated list of strings"

      field :names, type: [:string], paginate: true

      def call
        paginate :names, %w[Alice Bob Charlie David Eve Frank Grace Heidi]
      end

    end
  end
end
