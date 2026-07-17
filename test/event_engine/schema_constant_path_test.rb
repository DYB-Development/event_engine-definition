require "test_helper"

class SchemaConstantPathTest < DefinitionTestCase
  test "the canonical EventEngine::EventDefinition::Schema path resolves to the schema value object" do
    assert_same(
      EventEngine::EventDefinition::Schemas::Schema,
      EventEngine::EventDefinition::Schema
    )
  end

  test "a committed schema file's EventEngine::EventDefinition::Schema constructor still loads" do
    original = EventEngine::EventDefinition::Schema.new(
      event_name: :cow_fed,
      event_version: 1,
      event_type: :domain,
      required_inputs: [:cow],
      optional_inputs: [],
      payload_fields: []
    )

    reconstructed = eval(original.to_ruby)

    assert_equal original.event_name, reconstructed.event_name
  end
end
