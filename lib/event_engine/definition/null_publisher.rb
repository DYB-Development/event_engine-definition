module EventEngine
  module Definition
    class PublisherNotConfigured < Error; end

    class NullPublisher
      def publish(_event_name, **_envelope)
        raise PublisherNotConfigured,
              "No EventEngine::Definition.publisher configured. Wire a publisher " \
              "adapter (e.g. event_engine) before emitting events."
      end
    end
  end
end
