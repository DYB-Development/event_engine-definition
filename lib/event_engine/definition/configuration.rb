require "event_engine/subject_registry"

module EventEngine
  module Definition
    class Configuration
      attr_accessor :definitions_path, :helper_path, :root_module
      attr_writer :subject_registry

      def subject_registry
        @subject_registry ||= SubjectRegistry.new
      end
    end
  end
end
