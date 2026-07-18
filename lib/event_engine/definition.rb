# frozen_string_literal: true

require_relative "definition/version"

require "event_engine/subject_registry"
require "event_engine/event_definition"
require "event_engine/event_schema"
require "event_engine/schema_registry"
require "event_engine/lifecycle_definition"
require "event_engine/dsl_compiler"

module EventEngine
  module Definition
    class Error < StandardError; end

    class << self
      attr_writer :publisher

      def publisher
        @publisher ||= NullPublisher.new
      end

      def reset_publisher!
        @publisher = nil
      end
    end
  end
end

require "event_engine/definition/null_publisher"
require "event_engine/event_engine_helpers_writer"
require "event_engine/domain_pack_build"
