# frozen_string_literal: true

# The BearerSecurityScheme object defines the required spec for authentication via a bearer token.
#
# "components": {
#   "securitySchemes": {
#     "CoreAPI_Authenticator": {
#       "scheme": "bearer",
#       "type": "http"
#     }
#   }
# },
# "security": [
#   {
#     "CoreAPI_Authenticator": []
#   }
# ]

module Apia
  module OpenApi
    module Objects
      class BearerSecurityScheme

        include Apia::OpenApi::Helpers

        def initialize(spec:, authenticator:)
          @spec = spec
          @authenticator = authenticator
        end

        def add_to_spec
          @spec[:components][:securitySchemes] ||= {}
          @spec[:components][:securitySchemes][generate_id_from_definition(@authenticator.definition)] = {
            scheme: "bearer",
            type: "http"
          }

          @spec[:security] << {
            generate_id_from_definition(@authenticator.definition) => []
          }
        end

      end
    end
  end
end
