require "event_engine/event_definition"
require "event_engine/lifecycle_definition"

module EventEngine
  module DefinitionLoader
    def self.load!(path)
      before_events = EventEngine::EventDefinition.subclasses
      before_lifecycles = EventEngine::LifecycleDefinition.subclasses
      require_ruby_files(path)

      declared_events = EventEngine::EventDefinition.subclasses - before_events
      new_lifecycles = EventEngine::LifecycleDefinition.subclasses - before_lifecycles

      declared_events + new_lifecycles.flat_map(&:generated_events)
    end

    def self.require_ruby_files(path)
      Dir.glob(File.join(path, "**", "*.rb")).sort.each do |file|
        require File.expand_path(file)
      end
    end
  end
end
