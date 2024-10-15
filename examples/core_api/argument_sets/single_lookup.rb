# frozen_string_literal: true

module CoreAPI
  module ArgumentSets
    class SingleLookup < Apia::LookupArgumentSet

      name "Single Lookup"
      description "Provides for something to be looked up"

      argument :id, type: :string

    end
  end
end
