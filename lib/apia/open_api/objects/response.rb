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

        def initialize(spec:, path_ids:, route:, route_spec:, api_authenticator:)
          @spec = spec
          @path_ids = path_ids
          @route = route
          @endpoint = route.endpoint
          @route_spec = route_spec
          @api_authenticator = api_authenticator
          @http_status = @endpoint.definition.http_status
        end

        def add_to_spec
          add_sucessful_response_schema
          add_error_response_schemas
        end

        private

        def add_sucessful_response_schema
          content_schema = {
            properties: generate_properties_for_successful_response
          }
          required_fields = @endpoint.definition.fields.select { |_, field| field.condition.nil? }
          content_schema[:required] = required_fields.keys if required_fields.any?

          @route_spec[:responses] = {
            "#{@http_status}": {
              description: @endpoint.definition.description || "",
              content: {
                "application/json": {
                  schema: content_schema
                }
              }
            }
          }
        end

        def generate_properties_for_successful_response
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
          else
            properties[field_name] = generate_scalar_schema(field)
          end
          properties[field_name][:nullable] = true if field.null?
          properties
        end

        def build_properties_for_polymorph(field_name, field, properties)
          if field_includes_all_properties?(field)
            refs = []
            field.type.klass.definition.options.map do |_, polymorph_option|
              refs << generate_schema_ref(polymorph_option)
            end
            properties[field_name] = { oneOf: refs }
          else
            # We assume the partially selected attributes must be present in all of the polymorph options
            # and that each option returns the same data type for that attribute.
            # The same 'allOf workaround' is used here as for objects and enums below.
            ref = generate_schema_ref(
              field.type.klass.definition.options.values.first,
              id: generate_field_id(field_name),
              endpoint: @endpoint,
              path: [field]
            )

            properties[field_name] = { allOf: [ref] }
          end
          properties[field_name][:description] = field.description if field.description.present?
        end

        def build_properties_for_array(field_name, field, properties)
          if field.type.object? || field.type.enum?
            if field_includes_all_properties?(field)
              items = generate_schema_ref(field)
            else
              items = generate_schema_ref(
                field,
                id: generate_field_id(field_name),
                endpoint: @endpoint,
                path: [field]
              )
            end
          else
            items = { type: convert_type_to_open_api_data_type(field.type) }
          end
          return unless items

          properties[field_name] = {
            type: "array",
            items: items
          }
          properties[field_name][:description] = field.description if field.description.present?
        end

        # Using allOf is a 'workaround' so that we can include a description for the field
        # In OpenAPI 3.0 sibling properties are not allowed for $refs (but are allowed in 3.1)
        # We don't want to put the description on the $ref itself because the description is
        # specific to the endpoint and not necessarily applicable to all uses of the $ref.
        def build_properties_for_object_or_enum(field_name, field, properties)
          properties[field_name] = {}
          properties[field_name][:description] = field.description if field.description.present?
          if field_includes_all_properties?(field)
            ref = generate_schema_ref(field)
          else
            ref = generate_schema_ref(
              field,
              id: generate_field_id(field_name),
              endpoint: @endpoint,
              path: [field]
            )
          end
          properties[field_name][:allOf] = [ref]
        end

        def field_includes_all_properties?(field)
          field.include.nil?
        end

        def generate_field_id(field_name)
          [
            @route_spec[:operationId].gsub(":", "_").gsub("/", "_").camelize,
            @http_status,
            "Response",
            field_name.to_s
          ].flatten.join("_").camelize
        end

        def add_error_response_schemas
          grouped_potential_errors = potential_errors.map(&:definition).group_by do |d|
            d.http_status_code.to_s.to_sym
          end

          sorted_grouped_potential_errors = grouped_potential_errors.sort_by do |http_status_code, _|
            http_status_code.to_s.to_i
          end

          sorted_grouped_potential_errors.each do |http_status_code, potential_errors|
            add_error_response_schema_for_http_status_code(http_status_code, potential_errors)
          end
        end

        def api_authenticator_potential_errors
          @api_authenticator&.definition&.potential_errors
        end

        def potential_errors
          argument_set = @endpoint.definition.argument_set
          lookup_argument_set_errors = argument_set.collate_objects(Apia::ObjectSet.new).values.map do |o|
            o.type.klass.definition.try(:potential_errors)
          end.compact

          [
            api_authenticator_potential_errors,
            @route.controller&.definition&.authenticator&.definition&.potential_errors,
            @endpoint.definition&.authenticator&.definition&.potential_errors,
            lookup_argument_set_errors,
            @endpoint.definition.potential_errors
          ].compact.flatten
        end

        def add_error_response_schema_for_http_status_code(http_status_code, potential_errors)
          response_schema = generate_potential_error_ref(http_status_code, potential_errors)
          @route_spec[:responses].merge!(response_schema)
        end

        def generate_potential_error_ref(http_status_code, potential_errors)
          { "#{http_status_code}": generate_ref("responses", http_status_code, potential_errors) }
        end

        def generate_ref(namespace, http_status_code, definitions)
          id = generate_id_for_error_ref(namespace, http_status_code, definitions)
          if namespace == "responses"
            add_to_responses_components(http_status_code, definitions, id)
          else
            add_to_schemas_components(definitions.first, id)
          end
          { "$ref": "#/components/#{namespace}/#{id}" }
        end

        def generate_id_for_error_ref(namespace, http_status_code, definitions)
          suffix = namespace == "responses" ? "Response" : "Schema"
          api_authenticator_error_defs = api_authenticator_potential_errors.map(&:definition).select do |d|
            d.http_status_code.to_s == http_status_code.to_s
          end
          if api_authenticator_error_defs.any? && api_authenticator_error_defs == definitions
            "APIAuthenticator#{http_status_code}#{suffix}"
          elsif definitions.length == 1
            "#{generate_id_from_definition(definitions.first)}#{suffix}"
          else
            generate_short_error_ref(suffix, http_status_code, definitions, api_authenticator_error_defs)
          end
        end

        # When we have multiple errors for the same http status code, we need to generate a unique ID.
        # By default we join all the error names together, with the http status code and camelize them.
        # If this is too long, we use only the first and last two error names. Error names are sorted
        # alphabetically, which should ensure we do not generate the same ID to represent different sets of errors.
        # The length is important because the rubygems gem builder imposes a 100 character limit on filenames.
        def generate_short_error_ref(suffix, http_status_code, definitions, api_authenticator_error_defs)
          generated_ids = (definitions - api_authenticator_error_defs).map do |d|
            generate_id_from_definition(d)
          end.sort
          if generated_ids.join.length > 80
            sliced_ids = [generated_ids.first] + generated_ids[-2..]
          end
          [
            (sliced_ids || generated_ids).join,
            http_status_code,
            suffix.first(3)
          ].flatten.join("_").camelize
        end

        def add_to_responses_components(http_status_code, definitions, id)
          return unless @spec.dig(:components, :components, id).nil?

          component_schema = {
            description: "#{http_status_code} error response"
          }

          if definitions.length == 1
            definition = definitions.first
            component_schema[:description] = definition.description if definition.description.present?
            schema = generate_schema_properties_for_definition(definition)
          else # the same http status code is used for multiple errors
            one_of_id = "OneOf#{id}"
            @spec[:components][:schemas][one_of_id] = {
              oneOf: definitions.map { |d| generate_ref("schemas", http_status_code, [d]) }
            }

            schema = { "$ref": "#/components/schemas/#{one_of_id}" }
          end

          component_schema[:content] = {
            "application/json": {
              schema: schema
            }
          }
          @spec[:components][:responses] ||= {}
          @spec[:components][:responses][id] = component_schema
          component_schema
        end

        def generate_schema_properties_for_definition(definition)
          detail = generate_schema_ref(definition, id: generate_id_from_definition(definition))
          {
            properties: {
              code: {
                type: "string",
                enum: [definition.code]
              },
              description: { type: "string" },
              detail: detail
            }
          }
        end

        def add_to_schemas_components(definition, id)
          @spec[:components][:schemas] ||= {}
          component_schema = {
            type: "object"
          }
          component_schema[:description] = definition.description if definition.description.present?
          component_schema.merge!(generate_schema_properties_for_definition(definition))
          @spec[:components][:schemas][id] = component_schema
          component_schema
        end

      end
    end
  end
end
