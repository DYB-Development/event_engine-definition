require "test_helper"
require "tmpdir"

class DefinitionLoaderTest < DefinitionTestCase
  teardown do
    Object.send(:remove_const, :LoaderProbeCreated) if Object.const_defined?(:LoaderProbeCreated, false)
  end

  test "load! returns the definitions declared under the path" do
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "loader_probe_created.rb"), <<~RUBY)
        class LoaderProbeCreated < EventEngine::EventDefinition
          event_name :loader_probe_created
          event_type :domain
        end
      RUBY

      definitions = EventEngine::DefinitionLoader.load!(dir)

      assert_equal [:loader_probe_created], definitions.map { |klass| klass.schema.event_name }
    end
  end
end
