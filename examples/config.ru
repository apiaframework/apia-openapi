# frozen_string_literal: true

# Uncomment the following if you need to use a local version of the Apia gem
require "bundler/inline"
gemfile do
  gem "rack", "3.1.7"
  gem "apia", path: "../../apia"
  gem "activesupport"
  gem "puma", "~> 6.0"
  gem "pry"
end

$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))
$LOAD_PATH.unshift(File.expand_path(__dir__))

require "apia"
require "apia/rack"
require "apia/open_api"
require "core_api/base"

use Apia::OpenApi::Rack,
    api_class: "CoreAPI::Base",
    schema_path: "/core/v1/schema/openapi.json",
    base_url: "http://127.0.0.1:9292/core/v1/",
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
        "x-scope-prefix": "example.com/core/v1/",
        flows: {
          authorizationCode: {
            authorizationUrl: "https://example.com/oauth/authorize",
            tokenUrl: "https://example.com/oauth/token",
            refreshUrl: "https://example.com/oauth/token",
            scopes: {}
          }
        }
      }
    }
use Apia::Rack, CoreAPI::Base, "/core/v1", development: true

app = proc do
  [400, { "content-type" => "text/plain" },
   ["Apia Example API Server. Make a request to a an example API for example /core/v1."]]
end

run app
