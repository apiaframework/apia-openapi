# frozen_string_literal: true

module Apia
  module OpenApi
    class Rack

      def initialize(app, api_class:, schema_path:, **options)
        @app = app
        @api_class = api_class
        @schema_path = "/#{schema_path.sub(/\A\/+/, '').sub(/\/+\z/, '')}"
        @options = options
      end

      def development?
        env_is_dev = ENV["RACK_ENV"] == "development"
        return true if env_is_dev && @options[:development].nil?

        @options[:development] == true
      end

      def api_class
        return Object.const_get(@api_class) if @api_class.is_a?(String) && development?
        return @cached_api ||= Object.const_get(@api_class) if @api_class.is_a?(String)

        @api_class
      end

      def base_url
        @options[:base_url] || "https://api.example.com/api/v1"
      end

      def call(env)
        if @options[:hosts]&.none? { |host| host == env["HTTP_HOST"] }
          return @app.call(env)
        end

        unless env["PATH_INFO"] == @schema_path
          return @app.call(env)
        end

        specification = Specification.new(api_class, base_url, @options[:name])
        body = specification.json

        [200, { "content-type" => "application/json", "content-length" => body.bytesize.to_s }, [body]]
      end

    end
  end
end
