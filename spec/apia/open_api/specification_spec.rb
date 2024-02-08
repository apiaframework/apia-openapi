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

      spec = described_class.new(example_api, base_url, "Core")

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
