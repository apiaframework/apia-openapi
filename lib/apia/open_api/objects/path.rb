# frozen_string_literal: true

# A Path Object describes a single endpoint in the API
#
# "paths": {
#   "/data_centers/:data_center": {
#     "get": {
#       "operationId": "get:data_center",
#       "tags": ["Core"],
#       "parameters": [...],
#       "responses": {...},
#     }
#   },
#   "/virtual_machines/:virtual_machine/start": {
#     "post": {
#       "operationId": "post:virtual_machine_start",
#       "requestBody": {...}
#       "responses": {
#         "200": {...}
#       }
#     }
#   }
# }

module Apia
  module OpenApi
    module Objects
      class Path

        include Apia::OpenApi::Helpers

        def initialize(spec:, path_ids:, route:, name:, api_authenticator:)
          @spec = spec
          @path_ids = path_ids
          @route = route
          @api_authenticator = api_authenticator
          @route_spec = {
            operationId: convert_route_to_id,
            summary: @route.endpoint.definition.name,
            description: @route.endpoint.definition.description,
            tags: route.group ? get_group_tags(route.group) : [name],
            security: []
          }
        end

        def add_to_spec
          add_scopes_description
          add_scopes_security
          path = @route.path

          if @route.request_method == :get
            add_parameters
          else
            add_request_body
          end

          path = "/#{path}"
          # Remove the `:` from the url parameters in the path
          # This is because some tools based on the OpenAPI spec don't like the `:` in the path
          path = path.gsub(/:([^\/]+)/, '\1')

          @spec[:paths][path] ||= {}
          @spec[:paths][path][@route.request_method.to_s] = @route_spec

          add_responses
        end

        private

        # aka query params
        def add_parameters
          @route_spec[:parameters] ||= []

          @route.endpoint.definition.argument_set.definition.arguments.each_value do |arg|
            Parameters.new(spec: @spec, argument: arg, route_spec: @route_spec).add_to_spec
          end
        end

        def add_request_body
          RequestBody.new(spec: @spec, route: @route, route_spec: @route_spec).add_to_spec
        end

        def add_responses
          Response.new(
            spec: @spec,
            path_ids: @path_ids,
            route: @route,
            route_spec: @route_spec,
            api_authenticator: @api_authenticator
          ).add_to_spec
        end

        # Adds a description of the scopes to the route specification.
        #
        # This method checks if the route's endpoint definition has any scopes.
        # If there are scopes, it appends a description of the scopes to the existing route specification description.
        # The description of the scopes is formatted as a markdown list, with each scope represented as a bullet point.
        def add_scopes_description
          return unless @route.endpoint.definition.scopes.any?

          prefixes = {}
          @spec[:security].each do |auth|
            auth.each_key do |key|
              prefixes[key] = @spec[:components][:securitySchemes][key][:"x-scope-prefix"] || ""
            end
          end

          prefixes.each do |key, prefix|
            @route_spec[:description] =
              <<~DESCRIPTION
                #{@route_spec[:description]}
                ## #{key} Scopes
                #{@route.endpoint.definition.scopes.map do |scope|
                  "- `#{prefix ? "#{prefix}/" : ''}#{scope}`"
                end.join("\n")}
              DESCRIPTION
          end
        end

        # Adds scopes security to the OpenAPI path specification.
        #
        # This method checks if the route's endpoint definition has any scopes defined.
        # If scopes are present, it iterates over the security schemes in the OpenAPI
        # specification and adds the corresponding scopes to the route's security section.
        #
        # @return [void]
        def add_scopes_security
          return unless @route.endpoint.definition.scopes.any?

          @spec[:security].each do |auth|
            auth.each_key do |key|
              scopes = @route.endpoint.definition.scopes
              if scope_prefix = @spec[:components][:securitySchemes][key][:"x-scope-prefix"]
                scopes = scopes.map { |v| "#{scope_prefix}/#{v}" }
              end

              @route_spec[:security] << { key => scopes }
            end
          end
        end

        # It's worth creating a 'nice' operationId for each route, as this is used as the
        # basis for the method name when calling the endpoint using a generated client.
        def convert_route_to_id
          parts = @route.path.split("/")
          params = parts.each_with_object([]) do |part, memo|
            memo << part[1..] if part.start_with?(":")
          end
          result_parts = []

          parts.each do |part|
            if part.start_with?(":")
              part_without_prefix = part[1..]
              next if result_parts.include?(part_without_prefix)

              result_parts << part_without_prefix
            elsif params.none? { |param| part == param || part.match(/#{param.pluralize}/) }
              result_parts << part
            end
          end

          first_part = "#{@route.request_method}:"
          id = "#{first_part}#{result_parts.join('_')}"

          id = fallback_id(first_part) if @path_ids.include?(id)
          @path_ids << id

          id
        end

        # IDs can clash if two paths are different, but generate the same ID.
        # For example:
        # - /dns_zones/:dns_zone
        # - /dns/zones/:dns_zone
        # When there is a duplicate we fallback to using the path, but as the path
        # ID is used as the prefix for any $ref IDs, we need to make sure it's not
        # too long. This is because there is a 100 character filename limit imposed
        # by the rubygems gem builder.
        def fallback_id(first_part)
          last_part = @route.path
          if last_part.length >= 50
            last_part = last_part.split(/[_:\/]/).map do |word|
              word[0]
            end.join("_")
          end
          "#{first_part}#{last_part}"
        end

        # Returns an array of tags representing the group hierarchy for a given group.
        #
        # @param group [Group] The group for which to retrieve the tags.
        # @return [Array<String>] An array of tags representing the group hierarchy.
        def get_group_tags(group)
          tags = []
          current_group = group

          while current_group
            # Add tags to the spec global tags if they don't already exist
            # Include a description if the group has one.
            unless @spec[:tags].any? { |t| t[:name] == current_group.name }
              global_tag = { name: current_group.name }
              global_tag[:description] = current_group.description if current_group.description
              @spec[:tags] << global_tag

            end

            tags.unshift(current_group.name)
            current_group = current_group.parent
          end

          tags
        end

      end
    end
  end
end
