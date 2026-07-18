require "test_helper"
require "tempfile"

module EventEngine
  class EventEngineHelpersWriterTest < DefinitionTestCase

    def schema_with(required_inputs:, optional_inputs: [], domain: :sales)
      EventSchema.new.tap do |event_schema|
        event_schema.register(
          EventDefinition::Schema.new(
            event_name: :cow_fed,
            event_version: 1,
            event_type: :domain,
            domain: domain,
            required_inputs: required_inputs,
            optional_inputs: optional_inputs,
            payload_fields: []
          )
        )
        event_schema.finalize!
      end
    end

    def schema_across(domains)
      EventSchema.new.tap do |event_schema|
        domains.each do |domain|
          event_schema.register(
            EventDefinition::Schema.new(
              event_name: :cow_fed,
              event_version: 1,
              event_type: :domain,
              domain: domain,
              required_inputs: [:cow],
              optional_inputs: [],
              payload_fields: []
            )
          )
        end
        event_schema.finalize!
      end
    end

    def generate(event_schema, **options)
      Tempfile.create(["helpers", ".rb"]) do |file|
        EventEngineHelpersWriter.write(file.path, event_schema, **options)
        return File.read(file.path)
      end
    end

    test "wraps the events in a per-domain module" do
      source = generate(schema_with(required_inputs: [:cow]))

      assert_includes source, "module Sales"
    end

    test "writes a real self method for each event" do
      source = generate(schema_with(required_inputs: [:cow]))

      assert_includes source, "def self.cow_fed"
    end

    test "delegates to EventEngine.emit" do
      source = generate(schema_with(required_inputs: [:cow]))

      assert_includes source, "EventEngine.emit("
    end

    test "the emit target is configurable" do
      source = generate(
        schema_with(required_inputs: [:cow]),
        emit: "EventEngine::Definition.publisher.publish"
      )

      assert_includes source, "EventEngine::Definition.publisher.publish("
    end

    test "the root module is configurable" do
      source = generate(schema_with(required_inputs: [:cow]), root_module: "MarketingEvents")

      assert_includes source, "module MarketingEvents"
    end

    test "the header is configurable" do
      source = generate(schema_with(required_inputs: [:cow]), header: "# Generated. Do not edit.\n")

      assert_includes source, "# Generated. Do not edit."
    end

    test "a flat layout puts helpers directly under the root module" do
      source = generate(
        schema_with(required_inputs: [:cow]),
        root_module: "MarketingEvents",
        group_by_domain: false
      )

      assert_includes source, "module MarketingEvents\n  def self.cow_fed"
    end

    test "exposes a schema_path accessor pointing at the given schema filename" do
      source = generate(schema_with(required_inputs: [:cow]), schema_filename: "schema.json")

      assert_includes source, %(def self.schema_path\n    File.expand_path("schema.json", __dir__)\n  end)
    end

    test "passes the domain to emit" do
      source = generate(schema_with(required_inputs: [:cow]))

      assert_includes source, "domain: :sales"
    end

    test "a required input becomes a required keyword" do
      source = generate(schema_with(required_inputs: [:cow]))

      assert_includes source, "cow:,"
    end

    test "an optional input becomes a keyword defaulting to nil" do
      source = generate(schema_with(required_inputs: [:cow], optional_inputs: [:note]))

      assert_includes source, "note: nil"
    end

    test "the envelope keys are delegated to emit" do
      source = generate(schema_with(required_inputs: [:cow]))

      assert_includes source, "metadata: metadata"
    end

    test "does not generate flat singleton helpers" do
      source = generate(schema_with(required_inputs: [:cow]))

      refute_includes source, "class << self"
    end

    test "each domain produces its own module" do
      source = generate(schema_across([:sales, :marketing]))

      assert_includes source, "module Marketing"
    end

    test "a same-named event in two domains does not collide" do
      source = generate(schema_across([:sales, :marketing]))

      assert_equal 2, source.scan("def self.cow_fed").size
    end
  end
end
