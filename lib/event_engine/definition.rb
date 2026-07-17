# frozen_string_literal: true

require_relative "definition/version"

require "event_engine/process_type"
require "event_engine/subject_registry"
require "event_engine/event_definition"

module EventEngine
  module Definition
    class Error < StandardError; end
  end
end
