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
    base_url: "http://127.0.0.1:9292/core/v1/"
use Apia::Rack, CoreAPI::Base, "/core/v1", development: true

app = proc do
  [400, { "content-type" => "text/plain" },
   ["Apia Example API Server. Make a request to a an example API for example /core/v1."]]
end

run app
