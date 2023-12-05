# frozen_string_literal: true

require_relative "lib/apia/open_api/version"

Gem::Specification.new do |spec|
  spec.name = "apia-open_api"
  spec.version = Apia::OpenApi::VERSION
  spec.authors = ["Paul Sturgess"]

  spec.summary = "Apia OpenAPI spec generator"
  spec.homepage = "https://github.com/krystal/apia-openapi"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/krystal/apia-openapi"
  spec.metadata["changelog_uri"] = "https://github.com/krystal/apia-openapi/changelog.md"

  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(/\Aexe\//) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", ">= 6"
end
