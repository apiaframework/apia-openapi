# frozen_string_literal: true

# A Path Object describes a single endpoint in the API
#
# "paths": {
#   "/data_centers/:data_center": {
#     "get": {
#       "operationId": "get:data_center",
#       "tags": ["Core"],
#       "parameters": [...],
#       "responses": {...},
#     }
#   },
#   "/virtual_machines/:virtual_machine/start": {
#     "post": {
#       "operationId": "post:virtual_machine_start",
#       "requestBody": {...}
#       "responses": {
#         "200": {...}
#       }
#     }
#   }
# }

module Apia
  module OpenApi
    module Objects
      class Path

        include Apia::OpenApi::Helpers

        def initialize(spec:, path_ids:, route:, name:, api_authenticator:)
          @spec = spec
          @path_ids = path_ids
          @route = route
          @api_authenticator = api_authenticator
          @route_spec = {
            operationId: convert_route_to_id,
            tags: [name]
          }
        end

        def add_to_spec
          path = @route.path
          if @route.request_method == :get
            add_parameters
          else
            add_request_body
          end

          @spec[:paths]["/#{path}"] ||= {}
          @spec[:paths]["/#{path}"][@route.request_method.to_s] = @route_spec

          add_responses
        end

        private

        # aka query params
        def add_parameters
          @route_spec[:parameters] ||= []

          @route.endpoint.definition.argument_set.definition.arguments.each_value do |arg|
            Parameters.new(spec: @spec, argument: arg, route_spec: @route_spec).add_to_spec
          end
        end

        def add_request_body
          RequestBody.new(spec: @spec, route: @route, route_spec: @route_spec).add_to_spec
        end

        def add_responses
          Response.new(
            spec: @spec,
            path_ids: @path_ids,
            route: @route,
            route_spec: @route_spec,
            api_authenticator: @api_authenticator
          ).add_to_spec
        end

        # It's worth creating a 'nice' operationId for each route, as this is used as the
        # basis for the method name when calling the endpoint using a generated client.
        def convert_route_to_id
          parts = @route.path.split("/")
          params = parts.each_with_object([]) do |part, memo|
            memo << part[1..] if part.start_with?(":")
          end
          result_parts = []

          parts.each do |part|
            if part.start_with?(":")
              part_without_prefix = part[1..]
              next if result_parts.include?(part_without_prefix)

              result_parts << part_without_prefix
            elsif params.none? { |param| part == param || part.match(/#{param.pluralize}/) }
              result_parts << part
            end
          end

          id = "#{@route.request_method}:#{result_parts.join('_')}"
          if @path_ids.include?(id)
            id = "#{@route.request_method}:#{@route.path}"
          end
          @path_ids << id

          id
        end

      end
    end
  end
end
