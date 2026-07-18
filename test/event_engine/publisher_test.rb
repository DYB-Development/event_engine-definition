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
end
