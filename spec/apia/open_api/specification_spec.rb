# frozen_string_literal: true

require "spec_helper"
require "core_api/base"

RSpec.describe Apia::OpenApi::Specification do
  describe "#json" do
    it "produces OpenAPI JSON" do
      base_url = "http://127.0.0.1:9292/core/v1/"
      example_api = CoreAPI::Base

      spec = described_class.new(example_api, base_url, "Core")

      expected_spec = File.read("spec/support/fixtures/openapi.json").strip

      expect(spec.json).to eq(expected_spec)
    end
  end
end
