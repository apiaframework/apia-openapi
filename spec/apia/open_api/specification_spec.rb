# frozen_string_literal: true

require "spec_helper"
require "core_api/base"
require "openapi3_parser"

RSpec.describe Apia::OpenApi::Specification do
  let(:fixture_path) { File.expand_path("spec/support/fixtures/openapi.json") }

  describe "#json" do
    it "produces the expected OpenAPI JSON" do
      base_url = "http://127.0.0.1:9292/core/v1/"
      example_api = CoreAPI::Base

      spec = described_class.new(example_api, base_url, "Core",
                                 {
                                 info: {
                                   version: "2.1.3",
                                   contact: {
                                     name: "API Support",
                                     email: "support@example.com",
                                     url: "https://example.com/support"
                                   },
                                   license: {
                                     name: "Apache 2.0",
                                     url: "https://www.apache.org/licenses/LICENSE-2.0.html"
                                   },
                                   termsOfService: "https://example.com/terms",
                                   "x-added-info": "This is an example of adding custom information to the OpenAPI spec"
                                 },
                                 external_docs: {
                                  description: "Find out more",
                                  url: "https://example.com"
                                 },
                                 security_schemes: {
                                  OAuth2: {
                                    type: "oauth2",
                                    "x-scope-prefix": "example.com/core/v1",
                                    flows: {
                                      authorizationCode: {
                                        authorizationUrl: "https://example.com/oauth/authorize",
                                        tokenUrl: "https://example.com/oauth/token"
                                      }
                                    }
                                  }
                                 }
                                })

      # uncomment the following line for debugging :)
      # puts spec.json
      expected_spec = File.read(fixture_path).strip

      expect(spec.json).to eq(expected_spec)
    end

    # Obviously the fixture in this spec is hard-coded by us.
    # But the test above forces us to keep the fixture up to date.
    # And so each time we update the fixture, this test gives us
    # confidence that the resulting JSON is valid according to OpenAPI.
    it "produces a valid spec" do
      spec = Openapi3Parser.load_file(fixture_path)
      expect(spec.errors).to be_empty
      expect(spec.valid?).to be true
    end
  end
end
