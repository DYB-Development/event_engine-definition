# frozen_string_literal: true

require "json"
require "event_engine/dsl_compiler"
require "event_engine/subject_registry"
require "event_engine/event_engine_helpers_writer"

module EventEngine
  class DomainPackBuild
    PORT_EMIT = "EventEngine::Definition.publisher.publish"

    SCHEMA_FILENAME = "schema.json"

    HEADER = <<~RUBY.freeze
      # This file is authoritative in production.
      # It is generated from this pack's EventDefinitions.
      # Do not edit manually.

    RUBY

    def self.run(definitions, helper_path:, root_module:, header: HEADER,
                 subject_registry: SubjectRegistry.new)
      new(
        definitions,
        helper_path: helper_path,
        root_module: root_module,
        header: header,
        subject_registry: subject_registry
      ).run
    end

    def initialize(definitions, helper_path:, root_module:, header:, subject_registry:)
      @definitions = definitions
      @helper_path = helper_path
      @root_module = root_module
      @header = header
      @subject_registry = subject_registry
    end

    def run
      event_schema = compile
      write_helper(event_schema)
      write_schema_json(event_schema)
      self
    end

    def schema_path
      File.join(File.dirname(@helper_path), SCHEMA_FILENAME)
    end

    private

    def compile
      DslCompiler.compile(@definitions, subject_registry: @subject_registry).event_schema
    end

    def write_schema_json(event_schema)
      File.write(schema_path, JSON.pretty_generate(schemas(event_schema)))
    end

    def schemas(event_schema)
      event_schema.schemas_by_event.values.flat_map(&:values).map(&:to_h)
    end

    def write_helper(event_schema)
      EventEngineHelpersWriter.write(
        @helper_path,
        event_schema,
        root_module: @root_module,
        emit: PORT_EMIT,
        header: @header,
        group_by_domain: false,
        schema_filename: SCHEMA_FILENAME
      )
    end
  end
end
