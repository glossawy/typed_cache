# frozen_string_literal: true

module TypedCache
  # Instrumenter for cache operations
  module Instrumenter
    # @rbs! type event = Dry::Events::Event | ActiveSupport::Notifications::Event

    # @rbs [R](String, String, **untyped) { -> R } -> R
    def instrument(event_name, key, **payload)
      raise NotImplementedError, "#{self.class} must implement #instrument"
    end

    # @rbs (String, **untyped) { (event) -> void } -> void
    def subscribe(event_name, **filters, &block)
      raise NotImplementedError, "#{self.class} must implement #subscribe"
    end

    #: -> String
    def namespace
      config.namespace
    end

    # @rbs (String, String, **untyped) -> Hash[Symbol, untyped]
    def build_payload(operation, key, **payload)
      { namespace:, key:, operation: }.merge(payload)
    end

    # @rbs () -> bool
    def enabled? = config.enabled

    # @rbs (String) -> String
    def event_name(operation)
      "#{namespace}.#{operation}"
    end

    private

    # @rbs () -> TypedCache::_TypedCacheInstrumentationConfig
    def config
      TypedCache.config.instrumentation
    end
  end
end
