# frozen_string_literal: true

require 'dry/configurable'
require 'dry/struct'
require 'dry/types'

require 'typed_cache/either'
require 'typed_cache/maybe'

require 'typed_cache/cache_key'
require 'typed_cache/errors'
require 'typed_cache/namespace'
require 'typed_cache/registry'
require 'typed_cache/clock'

require 'typed_cache/store'
require 'typed_cache/instrumenter'
require 'typed_cache/backend'
require 'typed_cache/decorator'

require 'typed_cache/snapshot'
require 'typed_cache/cache_ref'

require 'typed_cache/cache_builder'

module TypedCache
  extend Dry::Configurable

  autoload :Backends, 'typed_cache/backends'
  autoload :Decorators, 'typed_cache/decorators'
  autoload :Instrumenters, 'typed_cache/instrumenters'

  # @rbs!
  #   interface _TypedCacheInstrumentationConfig
  #     def enabled: -> bool
  #     def namespace: -> String
  #     def instrumenter: -> Symbol
  #   end

  # @rbs!
  #   interface _TypedCacheConfig
  #     def default_namespace: -> String
  #     def cache_delimiter: -> String
  #     def instrumentation: -> _TypedCacheInstrumentationConfig
  #   end

  # @rbs! type typed_cache_config = _TypedCacheConfig

  # Configuration
  setting :default_namespace, default: 'typed_cache'
  setting :cache_delimiter, default: ':'

  setting :instrumentation do
    setting :enabled, default: false
    setting :namespace, default: 'typed_cache'
    setting :instrumenter, default: :default
  end

  class << self
    # @rbs! type cache_definition = TypedCache::_CacheDefinition

    # Returns a CacheBuilder with the fluent interface
    # @rbs () -> cache_definition
    def builder
      CacheBuilder.new(CacheDefinition.new, Backends, Decorators)
    end

    # @rbs! def config: -> _TypedCacheConfig

    # @rbs () -> singleton(Backends)
    def backends = Backends

    # @rbs () -> singleton(Decorators)
    def decorators = Decorators

    # @rbs () -> singleton(Instrumenters)
    def instrumenters = Instrumenters
  end
end

require 'typed_cache/railtie' if defined?(Rails::Railtie)
