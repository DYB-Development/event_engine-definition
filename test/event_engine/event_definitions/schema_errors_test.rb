require "test_helper"

module EventEngine
  class EventDefinitionSchemaErrorsTest < DefinitionTestCase
    test "schema_errors returns all validation errors" do
      klass = Class.new(EventDefinition) do

        input :cow
        required_payload :weight, from: :farmer, attr: :weight
        required_payload :event_type, from: :cow, attr: :weight
        optional_payload :weight, from: :cow, attr: :weight
        optional_payload :color, attr: :color
        optional_payload :texture, from: :cow
      end

      errors = klass.schema_errors

      assert_equal 7, errors.length
      assert errors.any? { |e| e.include?("event_name is required") }
      assert errors.any? { |e| e.include?("event_type is required") }
      assert errors.any? { |e| e.include?("unknown input") }
      assert errors.any? { |e| e.include?("reserved name") }
      assert errors.any? { |e| e.include?("duplicate payload field") }
      assert errors.any? { |e| e.include?("must have a from") }
      # attr: is now optional - omitting it means passthrough the input value directly
    end

    test "schema raises once with all errors" do
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

    test "valid_schema? returns false when errors exist" do
      klass = Class.new(EventDefinition) do
        event_name :bad_event
        event_type :domain

        input :cow
        required_payload :weight, from: :farmer, attr: :weight
      end

      assert_equal false, klass.valid_schema?
    end
  end
end
