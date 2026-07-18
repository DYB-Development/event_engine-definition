require "test_helper"

module EventEngine
  class EventDefinitionTest < DefinitionTestCase
    test "schema carries the declared subject" do
      definition = Class.new(EventEngine::EventDefinition) do
        event_name :processed
        event_type :domain
        subject :feeding
      end

      assert_equal :feeding, definition.schema.subject
    end

    test "schema carries the declared domain" do
      definition = Class.new(EventEngine::EventDefinition) do
        event_name :processed
        event_type :domain
        domain :sales
      end

      assert_equal :sales, definition.schema.domain
    end
  end
end
