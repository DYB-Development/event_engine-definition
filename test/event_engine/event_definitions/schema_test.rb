require "test_helper"

module EventEngine
  class EventDefinitionSchemaTest < DefinitionTestCase
    class CowFed < EventDefinition
      event_name :cow_fed
      event_type :domain
    end

    test "compiles event_name and event_type into schema" do
      schema = CowFed.schema

      assert_equal :cow_fed, schema.event_name
      assert_equal :domain, schema.event_type
    end

    test "raises error when event_name is missing" do
      klass = Class.new(EventDefinition) do
        event_type :domain
      end

      error = assert_raises(ArgumentError) { klass.schema }
      assert_match "event_name", error.message
    end

    test "raises error when event_type is missing" do
      klass = Class.new(EventDefinition) do
        event_name :cow_fed
      end

      error = assert_raises(ArgumentError) { klass.schema }
      assert_match "event_type", error.message
    end
  end
end
