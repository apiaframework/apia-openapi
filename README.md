# Apia OpenAPI Specification

This gem can generate an [OpenAPI](https://www.openapis.org/) compatible schema from an API implemented using [Apia](https://github.com/krystal/apia).

## Installation

TODO: Replace `UPDATE_WITH_YOUR_GEM_NAME_PRIOR_TO_RELEASE_TO_RUBYGEMS_ORG` with your gem name right after releasing it to RubyGems.org. Please do not do it earlier due to security reasons. Alternatively, replace this section with instructions to install your gem from git if you don't plan to release to RubyGems.org.

Install the gem and add to the application's Gemfile by executing:

    $ bundle add UPDATE_WITH_YOUR_GEM_NAME_PRIOR_TO_RELEASE_TO_RUBYGEMS_ORG

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install UPDATE_WITH_YOUR_GEM_NAME_PRIOR_TO_RELEASE_TO_RUBYGEMS_ORG

## Usage

The schema can be mounted in much the same way as an [Apia API](https://github.com/krystal/apia) itself.

For example, for a Ruby on Rails application:

```ruby
module MyApp
  class Application < Rails::Application

    config.middleware.use Apia::OpenApi::Rack,
                          api_class: "CoreAPI::Base",
                          schema_path: "/core/v1/schema/openapi.json",
                          base_url: "http://katapult-api.localhost/core/v1"

  end
end
```

Where `CoreAPI::Base` is the name of the API class that inherits from `Apia::API`.

## Generating a client library from the spec

It's possible to generate a client library from the generated OpenAPI schema using [OpenAPI Generator](https://openapi-generator.tech/).

For example we can generate a Ruby client with the following:

```bash
brew install openapi-generator
openapi-generator generate -i openapi.json -g ruby -o openapi-client --additional-properties=gemName=myapp-openapi-client,moduleName=MyAppOpenAPIClient
```

The generated client will be in the `openapi-client` directory and will contain a readme with instructions on how to use it.

## Development

After checking out the repo, run `bin/setup` to install dependencies.

In `/examples` there is an example Apia API application that can be used to try out the gem.

Run `rackup` from the root of `/examples` to start the [rack app](https://github.com/rack/rack) running the example API.
To view the generated OpenAPI schema, visit: http://127.0.0.1:9292/core/v1/schema/openapi.json
`/examples/config.ru` shows how to mount the schema endpoint.

The generated schema can be viewed, validated and tried out using the online [Swagger Editor](https://editor.swagger.io/). You'll need to add the bearer token to the swagger editor to authenticate the requests. After that, they should work as expected. The bearer token is defined in main_authenticator.rb.

Currently the online swagger-editor only allows the OpenAPI schema v3.0.0. But it's also possible to run the swagger-editor locally, which allows us to check against v3.1.0.

e.g with this docker-compose.yml file:

```yml
version: "3.3"
services:
  swagger-editor:
    image: swaggerapi/swagger-editor:next-v5
    container_name: "swagger-editor"
    ports:
      - "8081:80"
```

Run `docker-compose up` and visit http://localhost:8081 to view the swagger editor.

### Tests and Linting

- `bin/rspec`
- `bin/rubocop`

You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Releasing a new version

TODO: Write instructions for releasing a new version of the gem.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/krystal/apia-open_api.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
