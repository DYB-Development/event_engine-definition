require "test_helper"

class DefinitionConfigurationTest < DefinitionTestCase
  teardown do
    EventEngine::Definition.reset_configuration!
  end

  test "configure yields a configuration that persists the definitions path" do
    EventEngine::Definition.configure do |config|
      config.definitions_path = "app/event_definitions"
    end

    assert_equal "app/event_definitions", EventEngine::Definition.configuration.definitions_path
  end
end
