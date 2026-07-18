require "test_helper"
require "json"
require "tmpdir"

module EventEngine
  class DomainPackBuildTest < DefinitionTestCase
    def lead_created
      Class.new(EventDefinition) do
        event_name :lead_created
        event_type :domain
        domain :marketing
        input :email
      end
    end

    def build_into(dir)
      DomainPackBuild.run(
        [lead_created],
        helper_path: File.join(dir, "marketing_events.rb"),
        root_module: "MarketingEvents"
      )
    end

    test "writes the helper file with a port-emitting event method" do
      Dir.mktmpdir do |dir|
        build_into(dir)

        source = File.read(File.join(dir, "marketing_events.rb"))
        assert_includes source, "def self.lead_created"
      end
    end

    test "writes a schema.json holding the compiled event schemas" do
      Dir.mktmpdir do |dir|
        build_into(dir)

        schema = JSON.parse(File.read(File.join(dir, "schema.json")))
        assert_equal "lead_created", schema.first["event_name"]
      end
    end

    test "the generated helper exposes a schema_path accessor" do
      Dir.mktmpdir do |dir|
        build_into(dir)

        source = File.read(File.join(dir, "marketing_events.rb"))
        assert_includes source, "def self.schema_path"
      end
    end
  end
end
