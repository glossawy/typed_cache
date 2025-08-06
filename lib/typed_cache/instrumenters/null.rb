# frozen_string_literal: true

require 'singleton'

module TypedCache
  module Instrumenters
    # A no-op implementation used when instrumentation is disabled.
    # It fulfils the Instrumenter contract but simply yields.
    class Null
      include Instrumenter
      include Mixins::NamespacedSingleton

      # @rbs override
      # [R] (String, String, **untyped) { -> R } -> R
      def instrument(_operation, _key, **_payload)
        yield
      end

      # @rbs override
      # @rbs (String, **top) { (event) -> void } -> void
      def subscribe(_event_name, **_filters, &_block)
        # no-op
      end
    end
  end
end
