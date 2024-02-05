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
          @endpoint = endpoint # endpoint gets specified when we are dealing with a partial response
          @path = path
          @children = []
        end

        def add_to_spec
          if @definition.try(:type)&.polymorph?
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

        def error_definition?
          @definition.is_a?(Apia::Definitions::Error)
        end

        def enum_definition?
          @definition.try(:type)&.enum?
        end

        def generate_child_schemas
          if error_definition?
            @children = @definition.fields.values
          elsif @definition.type.argument_set?
            @children = @definition.type.klass.definition.arguments.values
            @schema[:description] ||=
              "All '#{@definition.name}[]' params are mutually exclusive, only one can be provided."
          elsif @definition.type.object?
            @children = @definition.type.klass.definition.fields.values
          elsif enum_definition?
            @children = @definition.type.klass.definition.values.values
          end

          return if @children.empty?

          all_properties_included = error_definition? || enum_definition? || @endpoint.nil?
          @children.each do |child|
            next unless @endpoint.nil? || (!enum_definition? && @endpoint.include_field?(@path + [child]))

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
          nullable = child.try(:null?)
          if enum_definition?
            schema[:type] = "string"
            schema[:enum] = @children.map { |c| c[:name] }
          elsif child.type.argument_set? || child.type.enum? || child.type.polymorph?
            schema[:type] = "object"
            schema[:properties] ||= {}
            schema[:properties][child.name.to_s] = generate_schema_ref(child, sibling_props: nullable)
          elsif child.type.object?
            generate_properties_for_object(schema, child, all_properties_included, nullable)
          else # scalar
            schema[:type] = "object"
            schema[:properties] ||= {}
            schema[:properties][child.name.to_s] = generate_scalar_schema(child)
          end

          if nullable
            schema[:properties][child.name.to_s][:nullable] = true
          end

          if child.try(:required?)
            schema[:required] ||= []
            schema[:required] << child.name.to_s
          end
          schema
        end

        def generate_properties_for_object(schema, child, all_properties_included, nullable)
          schema[:type] = "object"
          schema[:properties] ||= {}
          if all_properties_included
            ref = generate_schema_ref(child, sibling_props: nullable)
          else
            child_path = @path.nil? ? nil : @path + [child]

            # Nested partial fields in the response have the potential to generate
            # very long IDs, so we truncate them to avoid hitting the 100 character
            # filename limit imposed by the rubygems gem builder.
            truncated_id = @id.match(/^(.*?)\d*?(Response|Part).*$/)[1]
            ref = generate_schema_ref(
              child,
              id: "#{truncated_id}Part_#{child.name}".camelize,
              sibling_props: nullable,
              endpoint: @endpoint,
              path: child_path
            )
          end

          schema[:properties][child.name.to_s] = ref
        end

      end
    end
  end
end
