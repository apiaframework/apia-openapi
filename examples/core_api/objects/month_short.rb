# frozen_string_literal: true

module CoreAPI
  module Objects
    class MonthShort < Apia::Object

      description "Represents a month"

      field :number, type: :integer do
        backend { |t| t.strftime("%-m") }
      end

      field :month_short, type: :string do
        backend { |t| t.strftime("%b") }
      end

    end
  end
end
