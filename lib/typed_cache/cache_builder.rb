# frozen_string_literal: true

require 'typed_cache/namespace'
require 'typed_cache/cache_key'
require 'typed_cache/errors'

require 'typed_cache/store'
require 'typed_cache/backends'
require 'typed_cache/decorators'
require 'typed_cache/instrumenters'

require 'dry/struct'
require 'dry/types'

module TypedCache
  class CacheBuilder
    # @rbs! type config = TypedCache::typed_cache_config
    # @rbs! type instrumenter_source = :default | :dry | :rails | Instrumenter

    class BackendConfig < Dry::Struct
      attribute :name, Dry.Types::Symbol
      attribute :args, Dry.Types::Array.of(Dry.Types::Any)
      attribute :options, Dry.Types::Hash.map(Dry.Types::Symbol, Dry.Types::Any)
    end

    class DecoratorConfig < Dry::Struct
      attribute :name, Dry.Types::Symbol
      attribute :options, Dry.Types::Hash.map(Dry.Types::Symbol, Dry.Types::Any)
    end

    # @rbs (config, Registry[backend[untyped]], Registry[decorator[untyped]]) -> void
    def initialize(config, backend_registry = Backends, decorator_registry = Decorators)
      @config = config
      @backend_registry = backend_registry
      @decorator_registry = decorator_registry

      @backend_config = nil
      @decorator_configs = []
    end

    # Builds the cache - the only method that can fail
    # @rbs (?Namespace) -> either[Error, Store[V]]
    def build(namespace = Namespace.at(@config.instrumentation.namespace))
      validate_and_build(namespace)
    end

    # Familiar Ruby fluent interface - always succeeds
    # Invalid configurations are caught during build()
    # @rbs (Symbol, *untyped, **untyped) -> self
    def with_backend(name, *args, **options)
      @backend_config = BackendConfig.new(name:, args:, options:)
      self
    end

    # Adds an arbitrary decorator by registry key
    # @rbs (Symbol) -> self
    def with_decorator(name, **options)
      @decorator_configs << DecoratorConfig.new(name:, options:)
      self
    end

    # Adds instrumentation using the specified strategy.
    # @rbs (instrumenter_source) -> either[Error, self]
    def with_instrumentation(source = :default)
      @instrumenter_source = source
      self
    end

    private

    # @rbs (Namespace) -> either[Error, Store[V]]
    def validate_and_build(namespace)
      create_store(namespace).bind do |store|
        apply_decorators(store).bind do |decorated_store|
          apply_instrumentation(decorated_store)
        end
      end
    end

    # @rbs (Namespace) -> either[Error, Store[V]]
    def create_store(namespace)
      return Either.left(ArgumentError.new('Backend not configured')) unless @backend_config

      # Prepend namespace to the arguments for the backend constructor
      @backend_registry.resolve(@backend_config.name, namespace, *@backend_config.args, **@backend_config.options)
    end

    # @rbs (Store[V]) -> either[Error, Store[V]]
    def apply_decorators(store)
      return Either.right(store) if @decorator_configs.empty?

      names = @decorator_configs.map(&:name)

      name_counts = names.tally
      duplicates = name_counts.keys.select { |name| name_counts[name] > 1 }
      return Either.left(ArgumentError.new("Duplicate decorator: #{duplicates.join(", ")}")) if duplicates.any?

      @decorator_configs.reduce(Either.right(store)) do |result, decorator_config|
        result.bind do |current_store|
          @decorator_registry.resolve(decorator_config.name, current_store, **decorator_config.options)
        end
      end
    rescue => e
      Either.left(StoreError.new(:decorator_application, 'decorator', "Failed to apply decorator: #{e.message}", e))
    end

    def apply_instrumentation(store)
      return Either.right(store) unless @instrumenter_source

      instrumenter =
        case @instrumenter_source
        when Symbol
          Instrumenters.resolve(@instrumenter_source, namespace: @config.default_namespace)
        when Instrumenter
          Either.right(@instrumenter_source)
        else
          Either.left(TypedCache::TypeError.new(
            ':default | :dry | :rails | Instrumenter',
            @instrumenter_source.class.name,
            @instrumenter_source,
            "Invalid instrumenter source: #{@instrumenter_source.inspect}",
          ))
        end

      instrumenter.bind do |i|
        @decorator_registry.resolve(:instrumented, store, instrumenter: i)
      end
    end
  end
end
