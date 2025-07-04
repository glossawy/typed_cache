# frozen_string_literal: true

require 'zeitwerk'
require 'dry-configurable'
require 'concurrent-ruby'

# Load core registry before Zeitwerk
require_relative 'typed_cache/registry'
require_relative 'typed_cache/errors'

Zeitwerk::Loader.for_gem.setup

module TypedCache
  extend Dry::Configurable

  # @rbs!
  #   interface _TypedCacheInstrumentationConfig
  #     def enabled: -> bool
  #     def namespace: -> String
  #   end

  # @rbs!
  #   interface _TypedCacheConfig
  #     def default_namespace: -> String
  #     def instrumentation: -> _TypedCacheInstrumentationConfig
  #   end

  # @rbs! type typed_cache_config = _TypedCacheConfig

  # Configuration
  setting :default_namespace, default: 'typed_cache'

  setting :instrumentation do
    setting :enabled, default: false
    setting :namespace, default: 'typed_cache'
  end

  class << self
    # Returns a CacheBuilder with the fluent interface
    # @rbs [V] () -> CacheBuilder[V]
    def builder
      CacheBuilder.new(config, Backends, Decorators)
    end

    # @rbs! def config: -> _TypedCacheConfig

    # @rbs () -> singleton(Instrumentation)
    def instrumentation
      Instrumentation
    end

    # @rbs () -> Registry[backend[untyped]]
    def backends = Backends

    # @rbs () -> Register[decorator[untyped]]
    def decorators = Decorators
  end
end
