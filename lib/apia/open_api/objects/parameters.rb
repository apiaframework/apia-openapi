# frozen_string_literal: true

# Parameters describe the arguments that can be passed to an endpoint via the query string.
# We only declare these for GET requests, otherwise we define a request body.
#
# "parameters": [
#   {
#     "name": "data_center[id]",
#     "in": "query",
#     "schema": {
#       "type": "string"
#     }
#   },
#   {
#     "name": "data_center[permalink]",
#     "in": "query",
#     "schema": {
#       "type": "string"
#     }
#   }
# ]
module Apia
  module OpenApi
    module Objects
      class Parameters

        include Apia::OpenApi::Helpers

        def initialize(spec:, argument:, route_spec:)
          @spec = spec
          @argument = argument
          @route_spec = route_spec
        end

        def add_to_spec
          if @argument.type.argument_set?
            # complex argument sets are not supported in query params (e.g. nested objects)
            @argument.type.klass.definition.arguments.each_value do |child_arg|
              param = {
                name: "#{@argument.name}[#{child_arg.name}]",
                in: "query",
                schema: {
                  type: convert_type_to_open_api_data_type(child_arg.type)
                }
              }
              add_to_parameters(param)
            end
          elsif @argument.array?
            if @argument.type.enum? || @argument.type.object? # polymorph?
              items = generate_schema_ref(@argument.type.klass.definition)
              add_to_components_schemas(@argument)
            else
              items = { type: convert_type_to_open_api_data_type(@argument.type) }
            end

            param = {
              name: "#{@argument.name}[]",
              in: "query",
              schema: {
                type: "array",
                items: items
              }
            }
            add_to_parameters(param)
          elsif @argument.type.enum?
            param = {
              name: @argument.name.to_s,
              in: "query",
              schema: generate_schema_ref(@argument.type.klass.definition)
            }
            add_to_parameters(param)
            add_to_components_schemas(@argument)
          else
            param = {
              name: @argument.name.to_s,
              in: "query",
              schema: {
                type: convert_type_to_open_api_data_type(@argument.type)
              }
            }
            add_to_parameters(param)
          end
        end

        private

        def add_to_parameters(param)
          @route_spec[:parameters] << param
        end

      end
    end
  end
end
