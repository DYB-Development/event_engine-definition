module EventEngine
  class EventEngineHelpersWriter
    HEADER = <<~RUBY.freeze
      # This file is authoritative in production.
      # It is generated from EventDefinitions via:
      #
      #   bin/rails event_engine:schema:dump
      #
      # Do not edit manually.

    RUBY

    ENVELOPE_KEYS = DslCompiler::RESERVED_INPUT_NAMES

    def self.write(path, event_schema, root_module: "EventEngine", emit: "EventEngine.emit",
                   header: HEADER, group_by_domain: true, schema_filename: nil)
      File.write(
        path,
        generate(event_schema, root_module: root_module, emit: emit, header: header,
                               group_by_domain: group_by_domain, schema_filename: schema_filename)
      )
    end

    def self.generate(event_schema, root_module: "EventEngine", emit: "EventEngine.emit",
                      header: HEADER, group_by_domain: true, schema_filename: nil)
      body = group_by_domain ? grouped_body(event_schema, emit) : flat_body(event_schema, emit)
      body = "#{schema_path_accessor(schema_filename)}#{body}" if schema_filename

      "#{header}module #{root_module}\n#{body}end\n"
    end

    def self.schema_path_accessor(filename)
      "  def self.schema_path\n    File.expand_path(#{filename.inspect}, __dir__)\n  end\n"
    end

    def self.grouped_body(event_schema, emit)
      events_by_domain(event_schema).map do |domain, event_names|
        helpers = helpers_for(event_schema, domain, event_names, emit, indent: 4)

        "  module #{module_name(domain)}\n#{helpers}  end\n"
      end.join
    end

    def self.flat_body(event_schema, emit)
      events_by_domain(event_schema).map do |domain, event_names|
        helpers_for(event_schema, domain, event_names, emit, indent: 2)
      end.join
    end

    def self.helpers_for(event_schema, domain, event_names, emit, indent:)
      event_names.map do |event_name|
        helper(domain, event_schema.latest_for(event_name, domain: domain), emit, indent)
      end.join
    end

    def self.events_by_domain(event_schema)
      event_schema.schemas_by_event.keys
        .group_by { |(domain, _event_name)| domain }
        .transform_values { |pairs| pairs.map { |(_domain, event_name)| event_name }.sort }
    end

    def self.module_name(domain)
      domain.to_s.split("_").map(&:capitalize).join
    end

    def self.helper(domain, schema, emit, indent)
      pad = " " * indent
      call_pad = " " * (indent + 2)
      arg_pad = " " * (indent + 4)

      arguments = [
        schema.event_name.inspect,
        "domain: #{domain.inspect}",
        "inputs: #{inputs_hash(schema)}",
        *ENVELOPE_KEYS.map { |name| "#{name}: #{name}" }
      ].map { |argument| "#{arg_pad}#{argument}" }.join(",\n")

      "#{pad}def self.#{schema.event_name}(#{signature(schema)})\n" \
        "#{call_pad}#{emit}(\n" \
        "#{arguments}\n" \
        "#{call_pad})\n" \
        "#{pad}end\n"
    end

    def self.signature(schema)
      required = schema.required_inputs.map { |name| "#{name}:" }
      optional = schema.optional_inputs.map { |name| "#{name}: nil" }
      envelope = ENVELOPE_KEYS.map { |name| "#{name}: nil" }

      (required + optional + envelope).join(", ")
    end

    def self.inputs_hash(schema)
      inputs = schema.required_inputs + schema.optional_inputs
      return "{}" if inputs.empty?

      "{ #{inputs.map { |name| "#{name}: #{name}" }.join(", ")} }"
    end
  end
end
