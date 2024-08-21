# frozen_string_literal: true

require_relative "object_lookup"

module CoreAPI
  module ArgumentSets
    class TimeLookupArgumentSet < Apia::LookupArgumentSet

      argument :unix, type: :string, required: true
      argument :string, type: :string
      argument :nested, type: ObjectLookup

      potential_error "InvalidTime" do
        code :invalid_time
        http_status 400
      end

      def resolve
        if self[:unix]
          Time.at(self[:unix].to_i)
        elsif self[:string]
          begin
            Time.parse(self[:string])
          rescue ArgumentError
            raise_error "InvalidTime"
          end
        end
      end

    end
  end
end
