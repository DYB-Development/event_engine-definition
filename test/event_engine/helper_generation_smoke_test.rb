require "test_helper"
require "tempfile"

class HelperGenerationSmokeTest < DefinitionTestCase
  class CapturingPublisher
    attr_reader :calls

    def initialize
      @calls = []
    end

    def publish(event_name, **envelope)
      @calls << { event_name: event_name, **envelope }
    end
  end

  teardown do
    EventEngine::Definition.reset_publisher!
    Object.send(:remove_const, :MarketingEvents) if Object.const_defined?(:MarketingEvents, false)
  end

  def lead_created
    Class.new(EventEngine::EventDefinition) do
      event_name :lead_created
      event_type :domain
      domain :marketing
      input :email
    end
  end

  def install_generated_helpers(definitions)
    registry = EventEngine::DslCompiler.compile(definitions, subject_registry: EventEngine::SubjectRegistry.new)

    Tempfile.create(["marketing_events", ".rb"]) do |file|
      EventEngine::EventEngineHelpersWriter.write(
        file.path,
        registry.event_schema,
        root_module: "MarketingEvents",
        emit: "EventEngine::Definition.publisher.publish",
        group_by_domain: false
      )
      load file.path
    end
  end

  test "a domain gem's generated helper publishes through the port with no event_engine reference" do
    publisher = CapturingPublisher.new
    EventEngine::Definition.publisher = publisher

    install_generated_helpers([lead_created])
    MarketingEvents.lead_created(email: "lead@example.com")

    assert_equal(
      { event_name: :lead_created, domain: :marketing, inputs: { email: "lead@example.com" } },
      publisher.calls.first.slice(:event_name, :domain, :inputs)
    )
  end
end
