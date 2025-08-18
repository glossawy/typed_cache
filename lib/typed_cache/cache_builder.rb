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
  # @rbs!
  #  interface _CacheBuilder
  #    def build(namespace: Namespace) -> either[Error, Store[untyped]]
  #  end

  # @rbs!
  #  interface _CacheDefinition
  #    def with_backend(Symbol, *untyped, **untyped) -> (_CacheDefinition & _CacheBuilder)
  #    def with_decorator(Symbol, **untyped) -> self
  #    def with_instrumentation(Symbol) -> self
  #  end

  class BackendConfig < Dry::Struct
    attribute :name, Dry.Types::Symbol
    attribute :args, Dry.Types::Array.of(Dry.Types::Any)
    attribute :options, Dry.Types::Hash.map(Dry.Types::Symbol, Dry.Types::Any)
  end

  class DecoratorConfig < Dry::Struct
    attribute :name, Dry.Types::Symbol
    attribute :options, Dry.Types::Hash.map(Dry.Types::Symbol, Dry.Types::Any)
  end

  class CacheDefinition
    # @rbs! include _CacheDefinition

    # @rbs! type instrumenter_source = :default | :dry | :rails | Instrumenter

    attr_reader :backend_config #: BackendConfig?
    attr_reader :decorator_configs #: Array[DecoratorConfig]
    attr_reader :instrumenter_source #: instrumenter_source

    # @rbs (?BackendConfig?, ?Array[DecoratorConfig], ?instrumenter_source) -> void
    def initialize(backend_config = nil, decorator_configs = [], instrumenter_source = nil)
      @backend_config = backend_config
      @decorator_configs = decorator_configs
      @instrumenter_source = instrumenter_source
    end

    # @rbs override
    # @rbs (Symbol, *untyped, **untyped) -> self
    def with_backend(name, *args, **options)
      self.class.new(BackendConfig.new(name:, args:, options:), @decorator_configs)
    end

    # @rbs override
    # @rbs (Symbol, **untyped) -> self
    def with_decorator(name, **options)
      self.class.new(@backend_config, @decorator_configs + [DecoratorConfig.new(name:, options:)])
    end

    # @rbs override
    # @rbs (instrumenter_source) -> self
    def with_instrumentation(source = :default)
      self.class.new(@backend_config, @decorator_configs, source)
    end
  end

  class CacheBuilder
    # @rbs! include _CacheBuilder
    # @rbs! include _CacheDefinition

    # @rbs (?_CacheDefinition, ?Registry[backend[untyped]], ?Registry[decorator[untyped]]) -> void
    def initialize(cache_definition = CacheDefinition.new, backend_registry = Backends, decorator_registry = Decorators)
      @backend_registry = backend_registry
      @decorator_registry = decorator_registry

      @cache_definition = cache_definition
    end

    # Builds the cache using the given namespace, defaulting to the root namespace
    # @rbs (?Namespace) -> either[Error, Store[untyped]]
    def build(namespace = Namespace.root)
      validate_and_build(namespace)
    end

    # @rbs (Namespace) -> Store[untyped]
    def build!(namespace = Namespace.root)
      build(namespace).right_or_raise!
    end

    # Familiar Ruby fluent interface - always succeeds
    # Invalid configurations are caught during build()
    # @rbs (Symbol, *untyped, **untyped) -> self
    def with_backend(name, *args, **options)
      self.class.new(
        @cache_definition.with_backend(name, *args, **options),
        @backend_registry,
        @decorator_registry,
      )
    end

    # Adds an arbitrary decorator by registry key
    # @rbs (Symbol) -> self
    def with_decorator(name, **options)
      self.class.new(
        @cache_definition.with_decorator(name, **options),
        @backend_registry,
        @decorator_registry,
      )
    end

    # Adds instrumentation using the specified strategy.
    # @rbs (instrumenter_source) -> either[Error, self]
    def with_instrumentation(source = :default)
      self.class.new(
        @cache_definition.with_instrumentation(source),
        @backend_registry,
        @decorator_registry,
      )
    end

    private

    # @rbs (Namespace) -> either[Error, Store[V]]
    def validate_and_build(namespace)
      create_backend.bind do |backend|
        apply_decorators(backend).bind do |decorated_backend|
          apply_instrumentation(decorated_backend).bind do |instrumented_backend|
            Either.right(Store.new(namespace, instrumented_backend))
          end
        end
      end
    end

    # @rbs (Namespace) -> either[Error, Backend[untyped]]
    def create_backend
      backend_config = @cache_definition.backend_config

      return Either.left(ArgumentError.new('Backend not configured')) unless backend_config

      # Prepend namespace to the arguments for the backend constructor
      @backend_registry.resolve(backend_config.name, *backend_config.args, **backend_config.options)
    end

    # @rbs (Backend[untyped]) -> either[Error, Decorator[untyped]]
    def apply_decorators(backend)
      decorator_configs = @cache_definition.decorator_configs

      return Either.right(backend) if decorator_configs.empty?

      names = decorator_configs.map(&:name)

      name_counts = names.tally
      duplicates = name_counts.keys.select { |name| name_counts[name] > 1 }
      return Either.left(ArgumentError.new("Duplicate decorator: #{duplicates.join(", ")}")) if duplicates.any?

      decorator_configs.reduce(Either.right(backend)) do |result, decorator_config|
        result.bind do |current_backend|
          @decorator_registry.resolve(decorator_config.name, current_backend, **decorator_config.options)
        end
      end
    rescue => e
      Either.left(StoreError.new(:decorator_application, 'decorator', "Failed to apply decorator: #{e.message}", e))
    end

    # @rbs (Backend[untyped]) -> either[Error, Backend[untyped]]
    def apply_instrumentation(backend)
      instrumenter_source = @cache_definition.instrumenter_source

      return Either.right(backend) unless instrumenter_source

      instrumenter =
        case instrumenter_source
        when Symbol
          Instrumenters.resolve(instrumenter_source)
        when Instrumenter
          Either.right(instrumenter_source)
        else
          Either.left(TypedCache::TypeError.new(
            ':default | :dry | :rails | Instrumenter',
            instrumenter_source.class.name,
            instrumenter_source,
            "Invalid instrumenter source: #{instrumenter_source.inspect}",
          ))
        end

      instrumenter.bind do |i|
        @decorator_registry.resolve(:instrumented, backend, instrumenter: i)
      end
    end
  end
end
