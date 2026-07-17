module EventEngine
  class DslCompiler
    class InvalidEventNameError < StandardError; end
    class ReservedInputNameError < StandardError; end

    SNAKE_CASE = /\A[a-z][a-z0-9_]*\z/

    RESERVED_INPUT_NAMES = %i[
      event_version
      occurred_at
      metadata
      idempotency_key
      aggregate_type
      aggregate_id
      aggregate_version
    ].freeze

    def self.compile(definitions, subject_registry: SubjectRegistry.new)
      registry = SchemaRegistry.new
      subject_violations = []
      name_violations = []
      reserved_violations = []

      Array(definitions).each do |definition|
        schema = definition.schema
        record_subject_violation(schema, subject_violations, subject_registry)
        record_name_violation(schema, name_violations)
        record_reserved_input_violation(schema, reserved_violations)
        registry.register(schema)
      end

      raise_invalid_event_names(name_violations)
      raise_reserved_input_names(reserved_violations)
      raise_unknown_subjects(subject_violations)

      registry
    end

    def self.record_name_violation(schema, violations)
      return if schema.event_name.to_s.match?(SNAKE_CASE)

      violations << schema.event_name.inspect
    end

    def self.raise_invalid_event_names(violations)
      return if violations.empty?

      raise InvalidEventNameError, "event names must be snake_case: #{violations.join(", ")}"
    end

    def self.record_reserved_input_violation(schema, violations)
      inputs = schema.required_inputs + schema.optional_inputs
      collisions = inputs & RESERVED_INPUT_NAMES
      return if collisions.empty?

      violations << "#{schema.event_name}: #{collisions.join(", ")}"
    end

    def self.raise_reserved_input_names(violations)
      return if violations.empty?

      raise ReservedInputNameError,
            "input names collide with reserved envelope keys: #{violations.join("; ")}"
    end

    def self.record_subject_violation(schema, violations, subject_registry)
      return if schema.subject.nil?
      return if subject_registry.registered?(schema.subject)

      violations << "#{schema.event_name}: unknown subject #{schema.subject.inspect}"
    end

    def self.raise_unknown_subjects(violations)
      return if violations.empty?

      raise SubjectRegistry::UnknownSubjectError, violations.join(", ")
    end
  end
end
