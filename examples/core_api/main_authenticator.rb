# frozen_string_literal: true

module CoreAPI
  class MainAuthenticator < Apia::Authenticator

    BEARER_TOKEN = "example"

    type :bearer

    potential_error "InvalidToken" do
      code :invalid_token
      description "The token provided is invalid. In this example, you should provide '#{BEARER_TOKEN}'."
      http_status 403

      field :given_token, type: :string
    end

    def call
      configure_cors_response
      return if request.options?

      given_token = request.headers["authorization"]&.sub(/\ABearer /, "")
      if given_token == BEARER_TOKEN
        request.identity = { name: "Example User", id: 1234 }
      else
        raise_error "CoreAPI/MainAuthenticator/InvalidToken", given_token: given_token.to_s
      end
    end

    private

    # These are not strictly required, but it allows the app to work with swagger-ui.
    def configure_cors_response
      # Define a list of cors methods that are permitted for the request.
      cors.methods = %w[GET POST PUT PATCH DELETE OPTIONS]

      # Define a list of cors headers that are permitted for the request.
      cors.headers = %w[Authorization Content-Type] # or allow all with '*'

      # Define a the hostname to allow for CORS requests.
      cors.origin = "*" # or 'example.com'
    end

  end
end
