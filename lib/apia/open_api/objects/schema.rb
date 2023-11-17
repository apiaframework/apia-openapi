# frozen_string_literal: true

# Schema Objects loosley map to the re-usable parts of an Apia API, such as:
# ArgumentSet, Object, Enum, Polymorph
#
# "PaginationObject": {
#   "type": "object",
#   "properties": {
#     "current_page": {
#       "type": "integer"
#     },
#     "total_pages": {
#       "type": "integer"
#     },
#     "total": {
#       "type": "integer"
#     },
#     "per_page": {
#       "type": "integer"
#     },
#   }
# }
#
# We generate Schema Objects for two reasons:
# 1. They are added to the components section of the spec, so they can be referenced and re-used from elsewhere.
# e.g. the pagination object example above would be referenced from endpoint responses as:
# { "$ref": "#/components/schemas/PaginationObject" }
#
# 2. When the response does not include all fields from an existing Objects::Schema, we cannot use a $ref.
# So we generate a new Objects::Schema and include it 'inline' for that specific endpoint.
module Apia
  module OpenApi
    module Objects
      class Schema

        include Apia::OpenApi::Helpers

        def initialize(spec:, definition:, schema:, id:, endpoint: nil, path: nil)
          @spec = spec
          @definition = definition
          @schema = schema
          @id = id
          @endpoint = endpoint
          @path = path
          @children = []
        end

        def add_to_spec
          if @definition.type.polymorph?
            build_schema_for_polymorph
            return @schema
          end

          generate_child_schemas
          @schema
        end

        private

        def build_schema_for_polymorph
          @schema[:type] = "object"
          @schema[:properties] ||= {}
          refs = []
          @definition.type.klass.definition.options.map do |_, polymorph_option|
            refs << generate_schema_ref(polymorph_option)
          end
          @schema[:properties][@definition.name.to_s] = { oneOf: refs }
        end

        def generate_child_schemas
          if @definition.type.argument_set?
            @children = @definition.type.klass.definition.arguments.values
            @schema[:description] = "All '#{@definition.name}[]' params are mutually exclusive, only one can be provided."
          elsif @definition.type.object?
            @children = @definition.type.klass.definition.fields.values
          elsif @definition.type.enum?
            @children = @definition.type.klass.definition.values.values
          end

          return if @children.empty?

          all_properties_included = @definition.type.enum? || @endpoint.nil?
          @children.each do |child|
            next unless @endpoint.nil? || (!@definition.type.enum? && @endpoint.include_field?(@path + [child.name]))

            if child.respond_to?(:array?) && child.array?
              generate_schema_for_child_array(@schema, child, all_properties_included)
            else
              generate_schema_for_child(@schema, child, all_properties_included)
            end
          end
        end

        def generate_schema_for_child_array(schema, child, all_properties_included)
          child_schema = generate_schema_for_child({}, child, all_properties_included)
          items = child_schema.dig(:properties, child.name.to_s)
          return unless items.present?

          schema[:properties] ||= {}
          schema[:properties][child.name.to_s] = {
            type: "array",
            items: items
          }
        end

        def generate_schema_for_child(schema, child, all_properties_included)
          if @definition.type.enum?
            schema[:type] = "string"
            schema[:enum] = @children.map { |c| c[:name] }
          elsif child.type.argument_set? || child.type.enum? || child.type.polymorph?
            schema[:type] = "object"
            schema[:properties] ||= {}
            schema[:properties][child.name.to_s] = generate_schema_ref(child)
          elsif child.type.object?
            generate_properties_for_object(schema, child, all_properties_included)
          else # scalar
            schema[:type] = "object"
            schema[:properties] ||= {}
            schema[:properties][child.name.to_s] = {
              type: convert_type_to_open_api_data_type(child.type)
            }
          end

          if child.try(:required?)
            schema[:required] ||= []
            schema[:required] << child.name.to_s
          end
          schema
        end

        def generate_properties_for_object(schema, child, all_properties_included)
          schema[:type] = "object"
          schema[:properties] ||= {}
          if all_properties_included
            schema[:properties][child.name.to_s] = generate_schema_ref(child)
          else
            child_path = @path.nil? ? nil : @path + [child]
            schema[:properties][child.name.to_s] = generate_schema_ref(
              child,
              id: "#{@id}_#{child.name}",
              endpoint: @endpoint,
              path: child_path
            )
          end
        end

      end
    end
  end
end
