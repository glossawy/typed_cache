# frozen_string_literal: true

require 'dry/monitor'

module TypedCache
  module Instrumenters
    class Monitor
      include Instrumenter
      include Mixins::NamespacedSingleton

      # @rbs override
      #: [R] (String, String, **untyped) { -> R } -> R
      def instrument(operation, key, **payload, &block)
        payload = build_payload(operation, key, **payload)
        Dry::Monitor::Notifications.instrument(event_name(operation), payload, &block)
      end

      # @rbs override
      # @rbs (String, **top) { (event) -> void } -> void
      def subscribe(operation, **filters, &block)
        Dry::Monitor::Notifications.subscribe(event_name(operation), **filters, &block)
      end
    end
  end
end
