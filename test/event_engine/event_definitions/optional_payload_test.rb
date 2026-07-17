require "test_helper"

module EventEngine
  class EventDefinitionOptionalPayloadTest < DefinitionTestCase
    class CowFed < EventDefinition
      event_name :cow_fed
      event_type :domain

      input :cow
      optional_input :farmer

      required_payload :weight, from: :cow, attr: :weight
      optional_payload :name, from: :farmer, attr: :name
    end

    test "compiles optional payload field into schema" do
      schema = CowFed.schema
      field  = schema.payload_fields.find { |f| f[:name] == :name }

      assert_equal false, field[:required]
      assert_equal :farmer, field[:from]
      assert_equal :name, field[:attr]
    end

    test "optional payload may reference optional input" do
      schema = CowFed.schema
      field  = schema.payload_fields.find { |f| f[:name] == :name }

      assert_equal :farmer, field[:from]
    end
  end
end
