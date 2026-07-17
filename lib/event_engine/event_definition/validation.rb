module EventEngine
  class EventDefinition
    module Validation
      def validate_inputs!(inputs)
        declared = self.class.inputs
        provided = inputs.keys.map(&:to_sym)

        return if declared.empty?

        missing = declared - provided
        raise ArgumentError, "missing input: #{missing.join(', ')}" if missing.any?

        extra = provided - declared
        raise ArgumentError, "undeclared input: #{extra.join(', ')}" if extra.any?
      end
    end
  end
end
