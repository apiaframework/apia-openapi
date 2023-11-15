# frozen_string_literal: true

module CoreAPI
  module ArgumentSets
    class AnotherLookupArgumentSet < Apia::LookupArgumentSet

      argument :unix, type: :string
      argument :string, type: :string

    end
  end
end
