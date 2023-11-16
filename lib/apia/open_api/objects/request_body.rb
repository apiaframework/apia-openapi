# frozen_string_literal: true

# A RequestBody Object describes the payload body that can be passed to an endpoint
# These are declared (if necessary) for any endpoint that is not a GET request.
#
# "requestBody": {
#   "content": {
#     "application/json": {
#       "schema": {
#         "properties": {
#           "virtual_machine": {
#             "$ref": "#/components/schemas/CoreAPI_ArgumentSets_VirtualMachineLookup"
#           }
#         }
#       }
#     }
#   }
# }
module Apia
  module OpenApi
    module Objects
      class RequestBody

        include Apia::OpenApi::Helpers

        def initialize(spec:, route:, route_spec:)
          @spec = spec
          @route = route
          @route_spec = route_spec
          @properties = {}
        end

        def add_to_spec
          required = []
          @route.endpoint.definition.argument_set.definition.arguments.each_value do |arg|
            required << arg.name.to_s if arg.required?
            if arg.array?
              if arg.type.argument_set? || arg.type.enum?
                items = generate_schema_ref(arg.type.klass.definition)
                add_to_components_schemas(arg)
              else
                items = { type: convert_type_to_open_api_data_type(arg.type) }
              end

              @properties[arg.name.to_s] = {
                type: "array",
                items: items
              }
            elsif arg.type.argument_set? || arg.type.enum?
              @properties[arg.name.to_s] = generate_schema_ref(arg.type.klass.definition)
              add_to_components_schemas(arg)
            else # scalar
              @properties[arg.name.to_s] = {
                type: convert_type_to_open_api_data_type(arg.type)
              }
            end
          end

          schema = { properties: @properties }
          schema[:required] = required unless required.empty?

          @route_spec[:requestBody] = {
            content: {
              "application/json": {
                schema: schema
              }
            }
          }
        end

      end
    end
  end
end
