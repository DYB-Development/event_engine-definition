require "test_helper"

class SchemaToHTest < DefinitionTestCase
  test "schema serializes to a plain data hash" do
    schema = EventEngine::EventDefinition::Schema.new(
      event_name: "cow.fed",
      event_version: 1,
      event_type: "domain",
      process_type: :durable,
      subject: :feeding,
      domain: :sales,
      required_inputs: [:cow],
      optional_inputs: [:barn],
      payload_fields: [
        { name: :cow_id, required: true, from: :cow, attr: :id }
      ]
    )

    expected = {
      event_name: "cow.fed",
      event_version: 1,
      event_type: "domain",
      process_type: :durable,
      subject: :feeding,
      domain: :sales,
      required_inputs: [:cow],
      optional_inputs: [:barn],
      payload_fields: [
        { name: :cow_id, from: :cow, attr: :id, required: true }
      ],
      fingerprint: schema.fingerprint
    }

    assert_equal expected, schema.to_h
  end
end
