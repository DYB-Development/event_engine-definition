require "test_helper"

class PublisherTest < DefinitionTestCase
  teardown do
    EventEngine::Definition.reset_publisher!
  end

  test "the publisher port is configurable" do
    adapter = Object.new

    EventEngine::Definition.publisher = adapter

    assert_same adapter, EventEngine::Definition.publisher
  end

  test "an unconfigured publisher fails loudly when used" do
    error = assert_raises(EventEngine::Definition::PublisherNotConfigured) do
      EventEngine::Definition.publisher.publish(:lead_created, domain: :marketing, inputs: {})
    end

    assert_includes error.message, "publisher"
  end
end
