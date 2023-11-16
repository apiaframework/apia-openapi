# frozen_string_literal: true

# For each endpoint, we need to generate a response schema.
#
# "responses": {
#   "200": {
#     "description": "Format the given time",
#     "content": {
#       "application/json": {
#         "schema": {
#           "properties": {
#             "formatted_time": {
#               "type": "string"
#             }
#           },
#           "required": [
#             "formatted_time"
#           ]
#         }
#       }
#     }
#   }
# }
module Apia
  module OpenApi
    module Objects
      class Response

        include Apia::OpenApi::Helpers

        def initialize(spec:, path_ids:, route:, route_spec:)
          @spec = spec
          @path_ids = path_ids
          @route = route
          @endpoint = route.endpoint
          @route_spec = route_spec
        end

        def add_to_spec
          response_schema = {
            properties: generate_properties_for_response
          }

          required_fields = @endpoint.definition.fields.select { |_, field| field.condition.nil? }
          response_schema[:required] = required_fields.keys if required_fields.any?

          @route_spec[:responses] = {
            "#{@endpoint.definition.http_status}": {
              description: @endpoint.definition.description || "",
              content: {
                "application/json": {
                  schema: response_schema
                }
              }
            }
          }
        end

        private

        def generate_properties_for_response
          @endpoint.definition.fields.reduce({}) do |props, (name, field)|
            props.merge(generate_properties_for_field(name, field))
          end
        end

        # Response fields can often just point to a ref of a schema. But it's also possible to reference
        # a return type and not include all fields of that type. If `field.include` is defined, we need
        # to inspect it to determine which fields are included.
        def generate_properties_for_field(field_name, field)
          properties = {}
          if field.type.polymorph?
            build_properties_for_polymorph(field_name, field, properties)
          elsif field.array?
            build_properties_for_array(field_name, field, properties)
          elsif field.type.object? || field.type.enum?
            build_properties_for_object_or_enum(field_name, field, properties)
          else # scalar
            properties[field_name] = {
              type: convert_type_to_open_api_data_type(field.type)
            }
          end
          properties
        end

        def build_properties_for_polymorph(field_name, field, properties)
          if field_includes_all_properties?(field)
            refs = []
            field.type.klass.definition.options.map do |_, polymorph_option|
              refs << generate_schema_ref(polymorph_option.type.klass.definition)
              add_to_components_schemas(polymorph_option)
            end
            properties[field_name] = { oneOf: refs }
          else
            # TODO: https://github.com/krystal/apia-openapi/issues/13
          end
        end

        def build_properties_for_array(field_name, field, properties)
          if field.type.object? || field.type.enum?
            if field_includes_all_properties?(field)
              items = generate_schema_ref(field.type.klass.definition)
              add_to_components_schemas(field)
            else
              array_schema = {}
              Objects::Schema.new(
                spec: @spec,
                definition: field,
                schema: array_schema,
                endpoint: @endpoint,
                path: [field]
              ).add_to_spec
              if array_schema[:properties].any?
                items = array_schema
              end
            end
          else
            items = { type: convert_type_to_open_api_data_type(field.type) }
          end
          return unless items

          properties[field_name] = {
            type: "array",
            items: items
          }
        end

        def build_properties_for_object_or_enum(field_name, field, properties)
          if field_includes_all_properties?(field)
            properties[field_name] = generate_schema_ref(field.type.klass.definition)
            add_to_components_schemas(field)
          else
            object_schema = {}
            Objects::Schema.new(
              spec: @spec,
              definition: field,
              schema: object_schema,
              endpoint: @endpoint,
              path: [field]
            ).add_to_spec
            properties[field_name] = object_schema
          end
        end

        def field_includes_all_properties?(field)
          field.include.nil?
        end

      end
    end
  end
end
