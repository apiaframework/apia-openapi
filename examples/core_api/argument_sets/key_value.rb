# frozen_string_literal: true

module CoreAPI
  module ArgumentSets
    class KeyValue < Apia::ArgumentSet

      argument :key, type: :string, required: true
      argument :value, type: :string

    end
  end
end
