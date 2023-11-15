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

        def initialize(spec:, definition:, schema:, endpoint: nil, path: nil)
          @spec = spec
          @definition = definition
          @schema = schema
          @endpoint = endpoint
          @path = path
          @children = []
        end

        def add_to_spec
          if @definition.type.polymorph?
            build_schema_for_polymorph
            return @schema
          elsif @definition.respond_to?(:array?) && @definition.array? && @endpoint.present?
            build_schema_for_endpoint_array
          elsif @definition.respond_to?(:array?) && @definition.array? && @endpoint.nil?
            build_schema_for_array
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
            refs << generate_schema_ref(polymorph_option.type.klass.definition)
            add_to_components_schemas(polymorph_option)
          end
          @schema[:properties][@definition.name.to_s] = { oneOf: refs }
        end

        def build_schema_for_endpoint_array
          @array = true
          @schema[:type] = "object"
          @schema[:properties] ||= {}
          if @definition.type.argument_set? || @definition.type.enum? || @definition.type.object?
            if @definition.type.argument_set?
              # TODO: add array of argument sets to the example app (refer to CoreAPI::ArgumentSets::KeyValue)
              @children = @definition.type.klass.definition.arguments.values
            else
              @children = @definition.type.klass.definition.fields.values
            end
          else
            items = { type: convert_type_to_open_api_data_type(@definition.type) }
          end

          return unless items
          # TODO: ensure this is triggered by example API
          @schema[:properties][@definition.name.to_s] = {
            type: "array",
            items: items
          }
          @schema
        end

        #rubocop:disable Metrics/MethodLength, Metrics/BlockLength
        def build_schema_for_array
          @schema[:type] = "object"
          @schema[:properties] ||= {}

          puts ""
          puts "building schema for array endpoint: #{@endpoint}"
          puts "@definition.type: #{@definition.type.inspect} #{@definition.type.object?}"
          # if @definition.type.argument_set? || @definition.type.enum? || @definition.type.object?
          # if @definition.type.argument_set?
          #   @children = @definition.type.klass.definition.arguments.values
          # else
          #   @children = @definition.type.klass.definition.fields.values
          # end

          # puts "argset #{@definition.type.klass.definition.arguments.values}"
          puts "#{@definition.type.klass.definition.fields.each { |k,v| puts [k, v.type.klass].join(" - ") }; nil}" if @definition.type.object?
          puts ""
          if @definition.type.argument_set? || @definition.type.enum?
            items = { todo: "todo" }
          elsif @definition.type.object?
            properties = @definition.type.klass.definition.fields.reduce({}) do |props, (name, field)|
              props.merge(generate_properties_for_field(name, field))
            end
            items = {
              type: "object",
              properties: properties
            }
          else
            items = { type: convert_type_to_open_api_data_type(@definition.type) }
          end

          return unless items

          # TODO: ensure this is triggered by example API

          @schema[:properties][@definition.name.to_s] = {
            type: "array",
            items: items
          }
          @schema
        end

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
          if field.include.nil?
            refs = []
            field.type.klass.definition.options.map do |_, polymorph_option|
              refs << generate_schema_ref(polymorph_option.type.klass.definition)
              add_to_components_schemas(polymorph_option)
            end
            properties[field_name] = { oneOf: refs }
          else
            # TODO
          end
        end

        def build_properties_for_array(field_name, field, properties)
          if field.type.object? || field.type.enum? # polymorph?
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
          puts "field.include.nil? #{field.include.nil?}"
          field.include.nil?
        end





        def generate_child_schemas
          if @definition.type.argument_set?
            @children = @definition.type.klass.definition.arguments.values
          elsif @definition.type.object?
            @children = @definition.type.klass.definition.fields.values
          elsif @definition.type.enum?
            @children = @definition.type.klass.definition.values.values
          end

          return if @children.empty?

          all_properties_included = @definition.type.enum? || @endpoint.nil?
          @children.each do |child|
            next unless @endpoint.nil? || (!@definition.type.enum? && @endpoint.include_field?(@path + [child.name]))

            generate_schema_for_child(child, all_properties_included)
          end
        end

        def generate_schema_for_child(child, all_properties_included)
          puts "#{child.name.to_s} child.type: #{child.type} klass: #{child.type.klass} #{child.respond_to?(:array?) && child.array?}" if @array
          if @definition.type.enum?
            @schema[:type] = "string"
            @schema[:enum] = @children.map { |c| c[:name] }
          elsif child.respond_to?(:array?) && child.array?
            if child.type.object?
              items = generate_properties_for_object({}, child, all_properties_included)[:properties][child.name.to_s]
              # should we call generate_schema_for_child itself? hmmm
            else
              items = {
                type: convert_type_to_open_api_data_type(child.type)
              }
            end
            @schema[:properties][child.name.to_s] = {
              type: "array",
              items: items
            }
          elsif child.type.argument_set? || child.type.enum? || child.type.polymorph?
            @schema[:type] = "object"
            @schema[:properties] ||= {}
            @schema[:properties][child.name.to_s] = generate_schema_ref(child.type.klass.definition)
            add_to_components_schemas(child)
          elsif child.type.object?
            generate_properties_for_object(@schema, child, all_properties_included)
          else # scalar
            @schema[:type] = "object"
            @schema[:properties] ||= {}
            @schema[:properties][child.name.to_s] = {
              type: convert_type_to_open_api_data_type(child.type)
            }
          end
        end

        def generate_properties_for_object(schema, child, all_properties_included)
          schema[:type] = "object"
          schema[:properties] ||= {}
          if all_properties_included
            schema[:properties][child.name.to_s] = generate_schema_ref(child.type.klass.definition)
            add_to_components_schemas(child)
          else
            child_path = @path.nil? ? nil : @path + [child]
            child_schema = {}
            schema[:properties][child.name.to_s] = child_schema
            self.class.new(
              spec: @spec,
              definition: child,
              schema: child_schema,
              endpoint: @endpoint,
              path: child_path
            ).add_to_spec
          end
          schema
        end

      end
    end
  end
end
