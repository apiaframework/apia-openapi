# frozen_string_literal: true

require "core_api/objects/day"

module CoreAPI
  module Objects
    class Year < Apia::Object

      description "Represents a year"

      field :as_integer, type: :integer do
        backend(&:to_i)
      end

      field :as_string, type: :string do
        backend(&:to_s)
      end

      field :as_array_of_strings, type: [:string] do
        backend { |y| y.chars }
      end

      field :as_array_of_enums, type: [Day] do
        backend { %w[Sunday Monday] }
      end

    end
  end
end
