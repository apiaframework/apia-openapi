# frozen_string_literal: true

require "core_api/authenticators/time_now_authenticator"
require "core_api/objects/time_zone"

module CoreAPI
  module Endpoints
    class TimeNowEndpoint < Apia::Endpoint

      name "Time Now Endpoint"
      description "Returns the current time"

      scopes "time", "time:now"

      authenticator Authenticators::TimeNowAuthenticator

      argument :timezone, type: Objects::TimeZone
      argument :time_zones, [Objects::TimeZone], required: true do
        description "An array of any Timezone objects"
      end
      argument :filters, [:string]

      # specifying `include: true` is not the correct way to use the option, but it's here to
      # test that it doesn't break anything.
      field :time, type: Objects::Time, include: true do
        description "A Time object"
      end
      field :time_zones, type: [Objects::TimeZone]
      field :filters, [:string], null: true do
        description "An array of strings, might be null"
      end
      field :my_polymorph, type: Objects::MonthPolymorph do
        description "A polymorphic field!"
      end
      field :my_partial_polymorph, type: Objects::MonthPolymorph, include: "number", null: true

      scope "time"

      def call
        response.add_field :time, get_time_now
        response.add_field :filters, request.arguments[:filters]
        response.add_field :time_zones, request.arguments[:time_zones]
        response.add_field :my_polymorph, get_time_now
      end

      private

      def get_time_now
        Time.now
      end

    end
  end
end
