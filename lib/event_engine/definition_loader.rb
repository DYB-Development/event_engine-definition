require "event_engine/event_definition"

module EventEngine
  module DefinitionLoader
    def self.load!(path)
      before = EventEngine::EventDefinition.subclasses
      require_ruby_files(path)
      EventEngine::EventDefinition.subclasses - before
    end

    def self.require_ruby_files(path)
      Dir.glob(File.join(path, "**", "*.rb")).sort.each do |file|
        require File.expand_path(file)
      end
    end
  end
end
