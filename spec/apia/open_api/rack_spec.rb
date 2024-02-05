# frozen_string_literal: true

require "spec_helper"
require "core_api/base"
require "rack/mock"

class MockApi < Apia::API; end

RSpec.describe Apia::OpenApi::Rack do
  subject(:middleware) do
    described_class.new(app, api_class: api_class, schema_path: schema_path, **options)
  end
  let(:api_class) { "MockApi" }
  let(:schema_path) { "/schema" }
  let(:name_option) { "The API Name" }
  let(:options) { { name: name_option } }
  let(:uri) { "https://#{request_host}#{request_path}" }
  let(:default_base_url) { "https://api.example.com/api/v1" }

  let(:env) { Rack::MockRequest.env_for(uri, { "HTTP_HOST" => request_host }) }

  let(:mock_app_response) { "hello world" }
  let(:app) { -> (env) { [200, env, mock_app_response] } }

  let(:middleware_response) { middleware.call(env) }

  describe "#call" do
    context "when the request is not for the schema" do
      let(:request_host) { "example.com" }
      let(:request_path) { "/not/the/schema" }

      before do
        allow(Apia::OpenApi::Specification).to receive(:new)
      end

      it "returns the response from the app and not the schema" do
        expect(middleware_response).to eq([200, env, mock_app_response])

        expect(Apia::OpenApi::Specification).not_to have_received(:new)
      end
    end

    context "when the request is for the schema" do
      let(:request_host) { "example.com" }
      let(:request_path) { schema_path }
      let(:mock_spec) { instance_double(Apia::OpenApi::Specification, json: { mock: "spec" }.to_json) }

      before do
        allow(Apia::OpenApi::Specification).to receive(:new).and_wrap_original do
          mock_spec
        end
      end

      it "returns the OpenAPI specification" do
        expect(middleware_response).to match_array(
          [
            200,
            hash_including("Content-Type" => "application/json"),
            [mock_spec.json]
          ]
        )

        expect(Apia::OpenApi::Specification).to have_received(:new).with(
          MockApi, default_base_url, name_option
        )
      end

      context "when the base URL is provided" do
        let(:request_host) { "example.com" }
        let(:request_path) { schema_path }
        let(:base_url_option) { "https://my-api.com" }
        let(:options) do
          {
          name: name_option,
          base_url: base_url_option
        }
        end

        it "uses the provided base URL" do
          middleware_response

          expect(Apia::OpenApi::Specification).to have_received(:new).with(
            MockApi, base_url_option, name_option
          )
        end
      end

      context "when hosts is specified" do
        let(:host_option) { "my-custom-host.com" }
        let(:options) do
          {
            name: name_option,
            hosts: [host_option]
          }
        end

        context "when the request uri host is not in the hosts list" do
          let(:request_host) { "some-other-host.com" }
          let(:request_path) { schema_path }

          it "returns the response from the app and not the schema" do
            expect(middleware_response).to eq([200, env, mock_app_response])

            expect(Apia::OpenApi::Specification).not_to have_received(:new)
          end
        end

        context "when the request uri host is in the hosts list and the schema is requested" do
          let(:request_host) { host_option }
          let(:request_path) { schema_path }

          it "returns the OpenAPI specification" do
            expect(middleware_response).to match_array(
              [
                200,
                hash_including("Content-Type" => "application/json"),
                [mock_spec.json]
              ]
            )

            expect(Apia::OpenApi::Specification).to have_received(:new).with(
              MockApi, default_base_url, name_option
            )
          end
        end

        context "when the request uri host is in the hosts list and the schema is not requested" do
          let(:request_host) { host_option }
          let(:request_path) { "/not/the/schema" }

          it "returns the response from the app and not the schema" do
            expect(middleware_response).to eq([200, env, mock_app_response])

            expect(Apia::OpenApi::Specification).not_to have_received(:new)
          end
        end
      end

      context "when the API class arg is not a string" do
        let(:api_class) { MockApi }
        let(:request_host) { "example.com" }
        let(:request_path) { schema_path }

        it "will call the Specification with the api class" do
          expect(middleware_response).to match_array(
            [
              200,
              hash_including("Content-Type" => "application/json"),
              [mock_spec.json]
            ]
          )

          expect(Apia::OpenApi::Specification).to have_received(:new).with(
            api_class, default_base_url, name_option
          )
        end
      end
    end
  end
end
