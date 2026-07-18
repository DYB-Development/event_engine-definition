require "test_helper"
require "tmpdir"

class DomainPackBuildSmokeTest < DefinitionTestCase
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

  test "a built pack publishes through the port and locates its committed schema.json" do
    EventEngine::Definition.publisher = CapturingPublisher.new

    Dir.mktmpdir do |dir|
      EventEngine::DomainPackBuild.run(
        [lead_created],
        helper_path: File.join(dir, "marketing_events.rb"),
        root_module: "MarketingEvents"
      )
      load File.join(dir, "marketing_events.rb")

      MarketingEvents.lead_created(email: "lead@example.com")

      assert_equal :lead_created, EventEngine::Definition.publisher.calls.first[:event_name]
      assert_path_exists MarketingEvents.schema_path
    end
  end
end
