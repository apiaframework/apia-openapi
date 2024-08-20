# frozen_string_literal: true

require "active_support"
require "active_support/inflector"
require "active_support/core_ext"
require_relative "helpers"
require_relative "objects"

module Apia
  module OpenApi
    class Specification

      include Apia::OpenApi::Helpers

      OPEN_API_VERSION = "3.0.0" # The Ruby client generator currently only supports v3.0.0 https://openapi-generator.tech/

      def initialize(api, base_url, name)
        @api = api
        @base_url = base_url
        @name = name || "Core" # will be suffixed with 'Api' and used in the client generator
        @spec = {
          openapi: OPEN_API_VERSION,
          info: {},
          servers: [],
          paths: {},
          components: {
            schemas: {}
          },
          security: [],
          tags: [],
          "x-tagGroups": []
        }

        # path_ids is used to keep track of all the IDs of all the paths we've generated, to avoid duplicates
        # refer to the Path object for more info
        @path_ids = []
        build_spec
      end

      def json
        JSON.pretty_generate(@spec)
      end

      private

      def sort_hash_by_nested_tag(hash)
        hash.sort_by do |_, nested_hash|
          nested_hash.values.first[:tags]&.first
        end.to_h
      end

      def build_spec
        add_info
        add_servers
        add_paths
        add_security
        add_tag_groups

        @spec[:paths] = sort_hash_by_nested_tag(@spec[:paths])
      end

      def add_info
        title = @api.definition.name || @api.definition.id
        @spec[:info] = {
          version: "1.0.0",
          title: title
        }
        @spec[:info][:description] = @api.definition.description || "Welcome to the documentation for the #{title}"
      end

      def add_servers
        @spec[:servers] << { url: @base_url }
      end

      def add_paths
        @api.definition.route_set.routes.each do |route|
          # not all routes should be documented
          next unless route.group.nil? || route.group.schema?
          next unless route.endpoint.definition.schema?

          Objects::Path.new(
            spec: @spec,
            path_ids: @path_ids,
            route: route,
            name: @name,
            api_authenticator: @api.definition.authenticator
          ).add_to_spec
        end
      end

      def add_security
        @api.objects.select { |o| o.ancestors.include?(Apia::Authenticator) }.each do |authenticator|
          next unless authenticator.definition.type == :bearer

          Objects::BearerSecurityScheme.new(spec: @spec, authenticator: authenticator).add_to_spec
        end
      end

      def get_tag_group_index(tag)
        @spec[:"x-tagGroups"].each_with_index do |group, index|
          return index if !group.nil? && group[:name] == tag
        end

        nil
      end

      def add_tag_groups
        @spec[:paths].each_value do |methods|
          methods.each_value do |method_spec|
            method_spec[:tags].each_with_index do |tag, tag_index|
              unless @spec[:tags].any? { |t| t[:name] == tag }
                @spec[:tags] << { name: tag }
              end

              next if tag_index.zero?

              parent_tag = method_spec[:tags][tag_index - 1]
              index = get_tag_group_index(parent_tag)

              if index.nil? && method_spec[:tags].size > 1
                @spec[:"x-tagGroups"] << { name: parent_tag, tags: [parent_tag] }
                index = @spec[:"x-tagGroups"].size - 1
              end

              unless @spec[:"x-tagGroups"][index][:tags].include?(tag)
                @spec[:"x-tagGroups"][index][:tags] << tag
              end

              index = get_tag_group_index(tag)

              if index.nil? && method_spec[:tags].size > 1 && tag_index < method_spec[:tags].size - 1
                @spec[:"x-tagGroups"] << { name: tag, tags: [] }
              end
            end
          end
        end

        @spec[:tags].each do |tag|
          unless @spec[:"x-tagGroups"].any? { |group| group[:tags].include?(tag[:name]) }
            @spec[:"x-tagGroups"] << { name: tag[:name], tags: [tag[:name]] }
          end
        end

        @spec[:"x-tagGroups"].sort_by! { |group| group[:name] }
        @spec[:"x-tagGroups"].each { |group| group[:tags].sort! }
      end

    end
  end
end
