require "test_helper"

class SchemaSubjectTest < DefinitionTestCase
  test "schema retains its subject" do
    schema = EventEngine::EventDefinition::Schema.new(
      event_name: :cow_fed,
      event_version: 1,
      event_type: :domain,
      subject: :feeding,
      required_inputs: [:cow],
      optional_inputs: [],
      payload_fields: []
    )

    assert_equal :feeding, schema.subject
  end
end
