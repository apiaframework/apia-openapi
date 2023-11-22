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
          security: []
        }
        @path_ids = []
        build_spec
      end

      def json
        JSON.pretty_generate(@spec)
      end

      private

      def build_spec
        add_info
        add_servers
        add_paths
        add_security
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
          next unless route.endpoint.definition.schema? # not all routes should be documented

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

    end
  end
end
