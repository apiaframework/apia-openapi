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
        if type.klass == Apia::Scalars::UnixTime
          "integer"
        elsif type.klass == Apia::Scalars::Decimal
          "number"
        elsif type.klass == Apia::Scalars::Base64
          "string"
        else
          type.klass.definition.name.downcase
        end
      end

      def generate_scalar_schema(type)
        schema = {
          type: convert_type_to_open_api_data_type(type)
        }
        schema[:format] = "float" if type.klass == Apia::Scalars::Decimal
        schema
      end

      def generate_schema_ref(definition, id: nil, **schema_opts)
        id ||= generate_id_from_definition(definition.type.klass.definition)
        success = add_to_components_schemas(definition, id, **schema_opts)

        if success
          { "$ref": "#/components/schemas/#{id}" }
        else # no properties were defined, so just declare an object with unknown properties
          { type: "object" }
        end
      end

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
