require "test_helper"

module EventEngine
  class EventDefinitionRequiredPayloadTest < DefinitionTestCase
    class CowFed < EventDefinition
      event_name :cow_fed
      event_type :domain

      input :cow

      required_payload :cow_id, from: :cow, attr: :id
    end

    test "compiles required payload field into schema" do
      schema = CowFed.schema
      field  = schema.payload_fields.first

      assert_equal :cow_id, field[:name]
      assert_equal true, field[:required]
      assert_equal :cow, field[:from]
      assert_equal :id, field[:attr]
    end
  end
end
