# frozen_string_literal: true

# A collection of 'utility' methods used across the various OpenAPI::Objects
module Apia
  module OpenApi
    module Helpers

      # A component schema is a re-usable schema that can be referenced by other parts of the spec
      # e.g. { "$ref": "#/components/schemas/PaginationObject" }
      def add_to_components_schemas(definition, id, **schema_opts)
        return true unless @spec.dig(:components, :schemas, id).nil?

        component_schema = {}
        @spec[:components][:schemas][id] = component_schema
        Objects::Schema.new(
          spec: @spec,
          definition: definition,
          schema: component_schema,
          id: id,
          **schema_opts
        ).add_to_spec

        return true if component_schema.present?

        @spec[:components][:schemas].delete(id)
        false
      end

      def convert_type_to_open_api_data_type(type)
        case type.klass.to_s
        when "Apia::Scalars::String", "Apia::Scalars::Base64", "Apia::Scalars::Date"
          "string"
        when "Apia::Scalars::Integer", "Apia::Scalars::UnixTime"
          "integer"
        when "Apia::Scalars::Decimal"
          "number"
        when "Apia::Scalars::Boolean"
          "boolean"
        else
          raise "Unknown Apia type #{type.klass} mapping to OpenAPI type"
        end
      end

      def generate_scalar_schema(definition)
        type = definition.type
        schema = {
          type: convert_type_to_open_api_data_type(type)
        }
        schema[:description] = definition.description if definition.description.present?
        schema[:format] = "float" if type.klass == Apia::Scalars::Decimal
        schema[:format] = "date" if type.klass == Apia::Scalars::Date
        schema
      end

      def generate_array_schema(definition)
        type = definition.type
        schema = {
          type: "array",
          items: {
            type: convert_type_to_open_api_data_type(type)
          }
        }
        schema[:description] = definition.description if definition.description.present?
        schema[:items][:format] = "float" if type.klass == Apia::Scalars::Decimal
        schema[:items][:format] = "date" if type.klass == Apia::Scalars::Date
        schema
      end

      def generate_schema_ref(definition, id: nil, sibling_props: false, **schema_opts)
        id ||= generate_id_from_definition(definition.type.klass.definition)
        success = add_to_components_schemas(definition, id, **schema_opts)

        # sibling_props indicates we want to allow sibling properties (typically setting nullable: true)
        # In OpenAPI 3.0 sibling properties are not allowed for $refs (but are allowed in 3.1)
        # Using allOf is a workaround to allow us to set a ref as `nullable` in OpenAPI 3.0
        if success && sibling_props
          {
            allOf: [{ "$ref": "#/components/schemas/#{id}" }]
          }
        elsif success
          { "$ref": "#/components/schemas/#{id}" }
        else # no properties were defined, so just declare an object with unknown properties
          { type: "object" }
        end
      end

      # Converts the definition id to a short version:
      # e.g. CoreAPI/Objects/TimeZone => TimeZone
      def generate_id_from_definition(definition)
        definition.id.split("/").last
      end

      def formatted_description(description)
        return description if description.end_with?(".")

        "#{description}."
      end

    end
  end
end
