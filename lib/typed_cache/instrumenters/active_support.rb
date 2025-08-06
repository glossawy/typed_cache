# frozen_string_literal: true

require 'active_support/notifications'

module TypedCache
  module Instrumenters
    # Instrumenter for ActiveSupport::Notifications
    class ActiveSupport
      include Instrumenter
      include Mixins::NamespacedSingleton

      # @rbs override
      #: [R] (String, String, Hash[Symbol, untyped]) { -> R } -> R
      def instrument(operation, key, **payload, &block)
        payload = build_payload(operation, key, **payload)
        ::ActiveSupport::Notifications.instrument(event_name(operation), **payload, &block)
      end

      # @rbs override
      # @rbs (String, **top) { (event) -> void } -> void
      def subscribe(operation, **filters, &block)
        ::ActiveSupport::Notifications.monotonic_subscribe(event_name(operation), &block)
      end
    end
  end
end
