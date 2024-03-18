# frozen_string_literal: true

require_relative "lib/apia/open_api/version"

Gem::Specification.new do |spec|
  spec.name = "apia-open_api"
  spec.version = Apia::OpenApi::VERSION
  spec.authors = ["Paul Sturgess"]

  spec.summary = "Apia OpenAPI spec generator"
  spec.homepage = "https://github.com/apiaframework/apia-openapi"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/apiaframework/apia-openapi"
  spec.metadata["changelog_uri"] = "https://github.com/apiaframework/apia-openapi/changelog.md"

  spec.metadata["rubygems_mfa_required"] = "false" # rubocop:disable Gemspec/RequireMFA (enabling MFA means we cannot auto publish via the CI)

  spec.files = Dir[File.join("lib", "**", "*.rb")] +
               Dir["{*.gemspec,Gemfile,Rakefile,README.*,LICENSE*}"]
  spec.bindir = "exe"
  spec.executables = spec.files.grep(/\Aexe\//) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", ">= 6"
end
