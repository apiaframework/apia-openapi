# frozen_string_literal: true

require "core_api/authenticators/main_authenticator"
require "core_api/controllers/time_controller"
require "core_api/endpoints/test_endpoint"
require "core_api/endpoints/plain_text_endpoint"
require "core_api/endpoints/legacy_endpoint"
require "core_api/endpoints/paginated_endpoint"

module CoreAPI
  class Base < Apia::API

    authenticator Authenticators::MainAuthenticator

    name "Example API"

    scopes do
      add "time", "Allows time telling functions"
    end

    routes do # rubocop:disable Metrics/BlockLength
      schema

      get "time_formatting/incredibly/super/duper/long/format", controller: Controllers::TimeController,
                                                                endpoint: :format
      post "example/format", controller: Controllers::TimeController, endpoint: :format
      post "example/format_multiple", controller: Controllers::TimeController, endpoint: :format_multiple

      get "plain_text", endpoint: Endpoints::PlainTextEndpoint
      post "plain_text", endpoint: Endpoints::PlainTextEndpoint

      get "paginated", endpoint: Endpoints::PaginatedEndpoint

      group :time do
        name "Time functions"
        description "Everything related to time elements"
        get "time/now", endpoint: Endpoints::TimeNowEndpoint
        post "time/now", endpoint: Endpoints::TimeNowEndpoint

        get "test/:object", endpoint: Endpoints::TestEndpoint
        post "test/:object", endpoint: Endpoints::TestEndpoint

        group :formatting do
          name "Formatting"
          controller Controllers::TimeController

          get "time/formatting/incredibly/super/duper/long/format", endpoint: :format
          post "time/formatting/format", endpoint: :format
        end
      end

      # This endpoint should not be included in the OpenAPI spec
      group :legacy do
        no_schema

        get "legacy", endpoint: Endpoints::LegacyEndpoint
      end
    end

  end
end
