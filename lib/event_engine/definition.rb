# frozen_string_literal: true

require_relative "definition/version"

require "event_engine/process_type"
require "event_engine/subject_registry"
require "event_engine/event_definition"
require "event_engine/event_schema"
require "event_engine/schema_registry"
require "event_engine/lifecycle_definition"
require "event_engine/dsl_compiler"

module EventEngine
  module Definition
    class Error < StandardError; end
  end
end
