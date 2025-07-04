# frozen_string_literal: true

module TypedCache
  class CacheBuilder
    # @rbs! type config = TypedCache::typed_cache_config

    # @rbs (config, Registry[backend[untyped]], Registry[decorator[untyped]]) -> void
    def initialize(config, backend_registry = Backends, decorator_registry = Decorators)
      @config = config
      @backend_registry = backend_registry
      @decorator_registry = decorator_registry

      @backend_name = nil
      @backend_args = []
      @backend_options = {}
      @decorators = []
    end

    # Builds the cache - the only method that can fail
    # @rbs (?Namespace) -> either[Error, Store[V]]
    def build(namespace = Namespace.at(@config.default_namespace))
      validate_and_build(namespace)
    end

    # Familiar Ruby fluent interface - always succeeds
    # Invalid configurations are caught during build()
    # @rbs (Symbol, *untyped, **untyped) -> self
    def with_backend(name, *args, **options)
      @backend_name = name
      @backend_args = args
      @backend_options = options
      self
    end

    # Adds an arbitrary decorator by registry key
    # @rbs (Symbol) -> self
    def with_decorator(name)
      @decorators << name
      self
    end

    # @rbs () -> self
    def with_instrumentation
      with_decorator(:instrumented)
    end

    private

    # @rbs (Namespace) -> either[Error, Store[V]]
    def validate_and_build(namespace)
      create_store(namespace).bind do |store|
        apply_decorators(store)
      end
    end

    # @rbs (Namespace) -> either[Error, Store[V]]
    def create_store(namespace)
      return Either.left(ArgumentError.new('Backend not configured')) unless @backend_name

      # Prepend namespace to the arguments for the backend constructor
      @backend_registry.resolve(@backend_name, namespace, *@backend_args, **@backend_options)
    end

    # @rbs (Store[V]) -> either[Error, Store[V]]
    def apply_decorators(store)
      return Either.right(store) if @decorators.empty?

      @decorators.reduce(Either.right(store)) do |result, decorator_name|
        result.bind do |current_store|
          @decorator_registry.resolve(decorator_name, current_store)
        end
      end
    rescue => e
      Either.left(StoreError.new(:decorator_application, 'decorator', "Failed to apply decorator: #{e.message}", e))
    end
  end
end
