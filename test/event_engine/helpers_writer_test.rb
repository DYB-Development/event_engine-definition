require "test_helper"

class HelpersWriterTest < DefinitionTestCase
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

  def lead_created_definition
    Class.new(EventEngine::EventDefinition) do
      event_name :lead_created
      event_type :domain
      domain :marketing
      input :email
    end
  end

  def install(namespace: "MarketingEvents", definitions: [lead_created_definition])
    eval(EventEngine::Definition::HelpersWriter.generate(namespace: namespace, definitions: definitions))
  end

  test "generates a singleton method named after the event" do
    source = EventEngine::Definition::HelpersWriter.generate(
      namespace: "MarketingEvents",
      definitions: [lead_created_definition]
    )

    assert_includes source, "def self.lead_created"
  end

  test "the generated method publishes the event with its domain and inputs" do
    publisher = CapturingPublisher.new
    EventEngine::Definition.publisher = publisher

    install
    MarketingEvents.lead_created(email: "a@b.com")

    assert_equal(
      { event_name: :lead_created, domain: :marketing, inputs: { email: "a@b.com" } },
      publisher.calls.first
    )
  end
end
