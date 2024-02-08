# frozen_string_literal: true

module CoreAPI
  module ArgumentSets
    class ObjectLookup < Apia::LookupArgumentSet

      name "Object Lookup"
      description "Provides for objects to be looked up"

      argument :id, type: :string
      argument :permalink, type: :string do
        description "The permalink of the object to look up"
      end

      potential_error "ObjectNotFound" do
        code :object_not_found
        description "No object was found matching any of the criteria provided in the arguments"
        http_status 404
      end

      # this is intentionally a duplicate potential_error (it's also defined on the endpoint)
      # to test that we deduplicate them
      potential_error "SomethingWrong" do
        code :something_wrong
        http_status 400
      end

      resolver do |set, _request, _scope|
        objects = [{ id: "123", permalink: "perma-123" }]
        object = objects.find { |o| o[:id] == set[:id] || o[:permalink] == set[:permalink] }
        raise_error "ObjectNotFound" if object.nil?

        object
      end

    end
  end
end
