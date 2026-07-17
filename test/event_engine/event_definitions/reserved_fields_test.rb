require "test_helper"

class EventDefinitionReservedFieldsTest < DefinitionTestCase
  test "cannot use envelope fields as payload fields" do
    klass = Class.new(EventEngine::EventDefinition) do
      event_name :cow_fed
      event_type :domain
      input :cow
      required_payload :metadata, from: :cow, attr: :id
    end

    error = assert_raises(ArgumentError) { klass.schema }
    assert_includes error.message, "payload field uses reserved name: metadata"
  end
end
