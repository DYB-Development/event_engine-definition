module EventEngine
  module Definition
    class HelpersWriter
      def self.generate(namespace:, definitions:)
        bodies = definitions.map { |definition| method_source(definition.schema) }

        "module #{namespace}\n#{bodies.join("\n")}\nend\n"
      end

      def self.method_source(schema)
        <<~RUBY.gsub(/^(?=.)/, "  ").chomp
          def self.#{schema.event_name}(#{signature(schema)})
            EventEngine::Definition.publisher.publish(
              #{schema.event_name.inspect},
              domain: #{schema.domain.inspect},
              inputs: #{inputs_hash(schema)}
            )
          end
        RUBY
      end

      def self.signature(schema)
        required = schema.required_inputs.map { |name| "#{name}:" }
        optional = schema.optional_inputs.map { |name| "#{name}: nil" }

        (required + optional).join(", ")
      end

      def self.inputs_hash(schema)
        inputs = schema.required_inputs + schema.optional_inputs
        return "{}" if inputs.empty?

        "{ #{inputs.map { |name| "#{name}: #{name}" }.join(", ")} }"
      end
    end
  end
end
