# frozen_string_literal: true

Dir.glob(File.join(File.dirname(__FILE__), "objects", "*.rb")).each do |file|
  require_relative file
end

module Apia
  module OpenApi
    module Objects
    end
  end
end
