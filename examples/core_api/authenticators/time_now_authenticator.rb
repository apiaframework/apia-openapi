# frozen_string_literal: true

require "core_api/errors/rate_limit_reached"

module CoreAPI
  module Authenticators
    class TimeNowAuthenticator < Apia::Authenticator

      potential_error "WrongDayOfWeek" do
        code :wrong_day_of_week
        description "You called this API on the wrong day of the week, try again tomorrow"
        http_status 503
      end

    end
  end
end
