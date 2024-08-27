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
            generate_argument_set_params
          elsif @argument.array?
            if @argument.type.enum? || @argument.type.object?
              items = generate_schema_ref(@argument)
            else
              items = generate_scalar_schema(@argument)
            end

            param = {
              name: "#{@argument.name}[]",
              in: "query",
              schema: {
                type: "array",
                items: items
              }
            }
            param[:description] = @argument.description if @argument.description.present?
            param[:required] = true if @argument.required?
            add_to_parameters(param)
          elsif @argument.type.enum?
            param = {
              name: @argument.name.to_s,
              in: "query",
              schema: generate_schema_ref(@argument)
            }
            param[:description] = @argument.description if @argument.description.present?
            param[:required] = true if @argument.required?
            add_to_parameters(param)
          else
            param = {
              name: @argument.name.to_s,
              in: "query",
              schema: generate_scalar_schema(@argument)
            }
            param[:description] = @argument.description if @argument.description.present?

            add_pagination_params(param)

            param[:required] = true if @argument.required?
            add_to_parameters(param)
          end
        end

        private

        def add_pagination_params(param)
          if param[:name] == "page"
            param[:description] = "The page number to request. If not provided, the first page will be returned."
            param[:schema][:default] = 1
            param[:schema][:minimum] = 1
          elsif param[:name] == "per_page"
            param[:description] =
              "The number of items to return per page. If not provided, the default value will be used."
            param[:schema][:default] = 30
            param[:schema][:minimum] = 1
          end
        end

        # Complex argument sets are not supported in query params (e.g. nested objects)
        # For any LookupArgumentSet only one argument is expected to be provided.
        # However, OpenAPI does not currently support describing mutually exclusive query params.
        # refer to: https://swagger.io/docs/specification/describing-parameters/#dependencies
        def generate_argument_set_params
          @argument.type.klass.definition.arguments.each_value do |child_arg|
            # Complex argument sets are not supported in query params (e.g. nested objects)
            # https://github.com/apiaframework/apia-openapi/issues/66
            next if child_arg.type.argument_set?

            param = {
              in: "query"
            }

            description = []
            description << formatted_description(@argument.description) if @argument.description.present?
            description << formatted_description(child_arg.description) if child_arg.description.present?

            if @argument.type.id.end_with?("Lookup")
             description =  add_description_section(description, "All '#{@argument.name}[]' params are mutually exclusive, only one can be provided.")
            end

            if @argument.array
              param[:name] = "#{@argument.name}[][#{child_arg.name}]"
              param[:schema] = generate_array_schema(child_arg)

             description = add_description_section(description, "All `#{@argument.name}[]` params should have the same amount of elements.")
            else
              param[:name] = "#{@argument.name}[#{child_arg.name}]"
              param[:schema] = generate_scalar_schema(child_arg)
            end

            param[:description] = description.join(" ")
            add_to_parameters(param)
          end
        end

        # Adds a section to the description of a parameter.
        #
        # @param description [String] The current description of the parameter.
        # @param addition [String] The section to be added to the description.
        # @return [String] The updated description with the added section.
        def add_description_section(description, addition) 
          if description.present?
            description << "\n\n"
          end

          description << addition
        end

        def add_to_parameters(param)
          @route_spec[:parameters] << param
        end

      end
    end
  end
end
