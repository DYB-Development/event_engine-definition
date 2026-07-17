require "test_helper"

module EventEngine
  class EventDefinitionPayloadValidationTest < DefinitionTestCase
    test "raises error if payload field references unknown input" do
      error = assert_raises(ArgumentError) do
        Class.new(EventDefinition) do
          event_name :bad_event
          event_type :domain

          input :cow
          required_payload :weight, from: :farmer, attr: :weight
        end.schema
      end

      assert_match "unknown input", error.message
    end

    test "raises error on duplicate payload field names" do
       error = assert_raises(ArgumentError) do
        Class.new(EventDefinition) do
          event_name :bad_event
          event_type :domain

          input :cow
          required_payload :weight, from: :cow, attr: :weight
          optional_payload :weight, from: :cow, attr: :weight
        end.schema
      end

      assert_match "duplicate payload field", error.message
    end

    test "raises error if payload field uses reserved name" do
       error = assert_raises(ArgumentError) do
        Class.new(EventDefinition) do
          event_name :bad_event
          event_type :domain

          input :cow
          required_payload :event_type, from: :cow, attr: :weight
        end.schema
      end

      assert_match "reserved", error.message
    end
  end
end
