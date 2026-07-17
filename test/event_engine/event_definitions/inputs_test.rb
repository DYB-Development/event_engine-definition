require "test_helper"

module EventEngine
  class EventDefinitionInputsTest < DefinitionTestCase
    class CowFed < EventDefinition
      event_name :cow_fed
      event_type :domain

      input :cow
      optional_input :farmer
    end

    test "compiles inputs into schema" do
      schema = CowFed.schema

      assert_equal [:cow], schema.required_inputs
      assert_equal [:farmer], schema.optional_inputs
    end

    test "raises error on duplicate input" do
      error = assert_raises(ArgumentError) do
        Class.new(EventDefinition) do
          event_name :dup_test
          event_type :domain

          input :cow
          input :cow
        end
      end

      assert_match "duplicate input: cow", error.message
    end
  end
end
