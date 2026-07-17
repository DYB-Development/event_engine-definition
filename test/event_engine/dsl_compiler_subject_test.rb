require "test_helper"

class DslCompilerSubjectTest < DefinitionTestCase
  test "compile rejects a definition whose subject is not registered" do
    definition = Class.new(EventEngine::EventDefinition) do
      event_name :processed
      event_type :domain
      subject :unregistered
    end

    assert_raises(EventEngine::SubjectRegistry::UnknownSubjectError) do
      EventEngine::DslCompiler.compile([definition], subject_registry: EventEngine::SubjectRegistry.new)
    end
  end

  test "compile permits a definition whose subject is registered" do
    subjects = EventEngine::SubjectRegistry.define { subject :feeding }
    definition = Class.new(EventEngine::EventDefinition) do
      event_name :processed
      event_type :domain
      subject :feeding
    end

    assert_equal [:processed], EventEngine::DslCompiler.compile([definition], subject_registry: subjects).events
  end

  test "compile reports every unregistered subject in one error" do
    fed = Class.new(EventEngine::EventDefinition) do
      event_name :fed
      event_type :domain
      subject :feeding
    end
    shipped = Class.new(EventEngine::EventDefinition) do
      event_name :shipped
      event_type :domain
      subject :shipping
    end

    error = assert_raises(EventEngine::SubjectRegistry::UnknownSubjectError) do
      EventEngine::DslCompiler.compile([fed, shipped], subject_registry: EventEngine::SubjectRegistry.new)
    end

    assert_includes error.message, "shipping"
  end
end
