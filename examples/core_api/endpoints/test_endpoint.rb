# frozen_string_literal: true

require "core_api/argument_sets/object_lookup"

module CoreAPI
  module Endpoints
    class TestEndpoint < Apia::Endpoint

      name "Test Endpoint"
      description "Returns the current time"

      argument :object, type: ArgumentSets::ObjectLookup, required: true
      argument :scalar, type: :string, required: true do
        description "Any string will do, it's not validated"
      end

      field :time,
            type: Objects::Time,
            include: "unix,day_of_week,year[*,-as_integer,-as_array_of_strings,-as_array_of_enums]", null: true do
        condition do |o|
          o[:time].year.to_s == "2023"
        end
      end
      field :object_id, type: :string do
        backend { |o| o[:object_id][:id] }
      end

      scope "time"

      # The number of potential errors here is intentionally high to test that
      # we can successfully generate a truncated $ref ID for the OpenAPI spec.
      potential_error "SomethingVeryLongProblemBoom" do
        code :invalid_test
        http_status 400
      end

      potential_error "SoManyProblemsSoLittleTime" do
        code :so_many_problems
        http_status 400
      end

      potential_error "AnotherInvalidTest" do
        code :another_invalid_test
        http_status 400
      end

      potential_error "SomethingWrong" do
        code :something_wrong
        http_status 400
      end

      potential_error "ReallyWrong" do
        code :really_wrong
        http_status 400
      end

      def call
        object = request.arguments[:object].resolve
        response.add_field :time, get_time_now
        response.add_field :object_id, object
      end

      private

      def get_time_now
        Time.now
      end

    end
  end
end
