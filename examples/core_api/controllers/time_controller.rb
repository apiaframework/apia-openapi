# frozen_string_literal: true

require "core_api/objects/time"
require "core_api/authenticators/time_controller_authenticator"
require "core_api/argument_sets/time_lookup_argument_set"
require "core_api/endpoints/time_now_endpoint"

module CoreAPI
  module Controllers
    class TimeController < Apia::Controller

      name "Time API"
      description "Returns the time in varying ways"

      authenticator Authenticators::TimeControllerAuthenticator

      endpoint :now, Endpoints::TimeNowEndpoint

      # TODO: add example of multiple objects using the same objects, to ensure
      # we are handing circular references correctly
      endpoint :format do
        name "Format Time"
        description "Format the given time"
        scopes "time", "time:format"
        argument :time, type: ArgumentSets::TimeLookupArgumentSet, required: true do
          description "Time is a lookup argument set"
        end
        argument :timezone, type: Objects::TimeZone, required: true
        field :formatted_time, type: :string, null: true do
          description "Time formatted time as a string"
        end
        action do
          time = request.arguments[:time]
          response.add_field :formatted_time, time.resolve.to_s
        end
      end

      endpoint :format_multiple do
        name "Format Multiple Times"
        description "Format the given times"
        scopes "time", "time:format"
        argument :times, type: [ArgumentSets::TimeLookupArgumentSet], required: true
        field :formatted_times, type: [:string]
        field :times, type: [Objects::Time], include: "unix,year[as_string],as_array_of_objects[as_integer]"
        action do
          times = request.arguments[:times].map(&:resolve)

          response.add_field :formatted_times, times.map(&:to_s).join(", ")
          response.add_field :times, times
        end
      end

    end
  end
end
