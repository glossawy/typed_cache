# frozen_string_literal: true

module TypedCache
  # Generic interface for type-safe cache storage implementations
  # All stores are assumed to handle namespacing internally
  #
  # This interface follows the Command-Query Separation principle:
  # - Commands (set, delete, clear) perform actions and may return results
  # - Queries (get, key?, fetch) ask questions without side effects
  #
  # @rbs generic V
  class Store
    # @rbs! type cache_key = String | CacheKey

    # @rbs!
    #   interface _Store[V]
    #     def read: (cache_key) -> either[Error, Snapshot[maybe[V]]]
    #     def read_all: (Array[cache_key]) -> either[Error, Hash[CacheKey, Snapshot[V]]]
    #     def ref: (cache_key) -> CacheRef[V]
    #     def write: (cache_key, V) -> either[Error, Snapshot[V]]
    #     def write_all: (Hash[cache_key, V]) -> either[Error, Hash[CacheKey, Snapshot[V]]]
    #     def delete: (cache_key) -> either[Error, maybe[V]]
    #     def key?: (cache_key) -> bool
    #     def clear: () -> void
    #     def fetch: (cache_key) { (CacheKey) -> V? } -> either[Error, Snapshot[maybe[V]]]
    #     def fetch_all: (Array[cache_key]) { (CacheKey) -> V? } -> either[Error, Array[Snapshot[V]]]
    #     def fetch_or_compute_all: (Array[cache_key]) { (Array[CacheKey]) -> Hash[CacheKey, V] } -> either[Error, Hash[CacheKey, Snapshot[V]]]
    #     def namespace: () -> Namespace
    #     def with_namespace: (Namespace) -> Store[V]
    #     def at_namespace: (Namespace) -> Store[V]
    #     def cache_for: [T] (Class[T], at: (Namespace | String | Array[String])) -> Store[T]
    #     def backend: () -> Backend[V]
    #   end
    #   include _Store[V]

    attr_reader :namespace #: Namespace
    attr_reader :backend #: Backend[V]

    # @rbs (Namespace, Backend[V]) -> void
    def initialize(namespace, backend)
      @namespace = namespace
      @backend = backend
    end

    # @rbs (Store[V]) -> void
    def initialize_copy(other)
      super
      @namespace = other.namespace
    end

    # Retrieves a value from the cache
    # @rbs (cache_key, **top) -> either[Error, Snapshot[maybe[V]]]
    def read(key, **kwargs)
      key = namespaced_key(key)

      value = backend.read(key, **kwargs)

      Either.right(
        if value.nil?
          Snapshot.cached(key, Maybe.none)
        else
          Snapshot.cached(key, Maybe.some(value))
        end,
      )
    rescue => e
      Either.left(StoreError.new(:read, key, "Failed to read from cache: #{e.message}", e))
    end

    # @rbs (Array[cache_key], **top) -> either[Error, Hash[CacheKey, Snapshot[V]]]
    def read_all(keys, **kwargs)
      keys = keys.map { |key| namespaced_key(key) }
      cached_values = backend.read_multi(keys, **kwargs)

      keys.filter_map do |key|
        next unless cached_values.key?(key.to_s)

        [key, Snapshot.cached(key, cached_values[key.to_s])]
      end.to_h
    end

    # Retrieves a cache reference for a key
    # @rbs (cache_key) -> CacheRef[V]
    def ref(key)
      CacheRef.new(self, namespaced_key(key))
    end

    # Stores a value in the cache
    # @rbs (cache_key, V, **top) -> either[Error, Snapshot[V]]
    def write(key, value, **kwargs)
      key = namespaced_key(key)
      backend.write(key, value, **kwargs)

      Either.right(Snapshot.cached(key, value))
    rescue => e
      Either.left(StoreError.new(:write, key, "Failed to write to cache: #{e.message}", e))
    end

    # @rbs (Hash[cache_key, V], **top) -> either[Error, Hash[CacheKey, Snapshot[V]]]

    def write_all(values, **kwargs)
      values.transform_keys! { |key| namespaced_key(key) }

      written_values = backend.write_multi(values, **kwargs)
      written_values.transform_values { |value| Snapshot.cached(key, value) }
    end

    # Removes a value from the cache, returning the removed value
    # @rbs (cache_key) -> either[Error, maybe[V]]
    def delete(key)
      key = namespaced_key(key)
      deleted_value = backend.delete(key)

      Either.right(Maybe.wrap(deleted_value))
    rescue => e
      Either.left(StoreError.new(:delete, key, "Failed to delete from cache: #{e.message}", e))
    end

    # Checks if a key exists in the cache (query operation)
    # @rbs (cache_key) -> bool
    def key?(key)
      key = namespaced_key(key)
      backend.key?(key)
    end

    # Clears all values from the cache namespace (command operation)
    # @rbs () -> void
    def clear
      backend.clear
    end

    # Fetches a value from cache, computing and storing it if not found
    # This is an atomic operation that combines read and write
    # @rbs (cache_key, **top) { (CacheKey) -> V? } -> either[Error, Snapshot[maybe[V]]]
    def fetch(key, **kwargs, &block)
      key = namespaced_key(key)
      computed = false
      result = backend.fetch(key, **kwargs) do
        computed = true
        yield(key)
      end

      if result.nil?
        Either.right(Snapshot.cached(key, Maybe.none))
      else
        snapshot = computed ? Snapshot.computed(key, result) : Snapshot.cached(key, result)
        Either.right(snapshot.map { Maybe.wrap(_1) })
      end
    rescue => e
      Either.left(StoreError.new(:fetch, key, "Failed to fetch from cache: #{e.message}", e))
    end

    # @rbs (Array[cache_key], **top) { (CacheKey) -> V? } -> either[Error, Hash[CacheKey, Snapshot[V]]]
    def fetch_all(keys, **kwargs, &block)
      keys = keys.map { |key| namespaced_key(key) }
      computed_keys = Set.new
      fetched_values = backend.fetch_multi(keys, **kwargs) do |key|
        computed_keys << key
        yield(key)
      end

      Either.right(keys.to_h do |key|
        snapshot = computed_keys.include?(key) ? Snapshot.computed(key, fetched_values[key]) : Snapshot.cached(key, fetched_values[key])
        [key, snapshot]
      end)
    rescue => e
      Either.left(StoreError.new(:fetch_all, keys, "Failed to fetch from cache: #{e.message}", e))
    end

    # @rbs (Array[cache_key], **top) { (Array[CacheKey]) -> Hash[CacheKey, V] } -> either[Error, Hash[CacheKey, Snapshot[V]]]
    def fetch_or_compute_all(keys, **kwargs, &block)
      keys = keys.map { |key| namespaced_key(key) }
      cached_values = backend.read_multi(keys, **kwargs)
      missing_keys = keys - cached_values.keys

      if missing_keys.any?
        computed_values = yield(missing_keys)
        backend.write_multi(computed_values, **kwargs)
      end

      cached_values.transform_values! { |value| Snapshot.cached(key, value) }
      computed_values.transform_values! { |value| Snapshot.computed(key, value) }

      cached_values.merge(computed_values)
    end

    # @rbs () -> Instrumenter
    def instrumenter = @instrumenter ||= Instrumenters::Null.new(namespace:)

    # Accepts a String segment or a fully-formed Namespace and returns a cloned
    # store scoped to that namespace.
    #: (Namespace | String | Array[String]) -> Store[V]
    def with_namespace(ns)
      new_namespace =
        case ns
        when Namespace then ns
        when Array then namespace.join(*ns)
        else
          # treat as nested segment under the current namespace
          namespace.nested(ns.to_s)
        end

      clone.tap { |store| store.namespace = new_namespace }
    end

    # @rbs [T] (Class[T], at: (Namespace | String | Array[String])) -> Store[T]
    def cache_for(klass, at: nil)
      new_namespace =
        case at
        when Namespace then at
        when Array then namespace.join(*at)
        else
          namespace.nested(at.to_s)
        end

      clone.tap { |store| store.namespace = new_namespace }
    end

    alias at_namespace with_namespace

    # @rbs () -> String
    def to_s = "Store(#{namespace})"

    # @rbs () -> String
    def inspect = "Store(#{namespace}, #{backend.inspect})"

    protected

    attr_writer :namespace

    private

    #: (cache_key) -> CacheKey
    def namespaced_key(key)
      key.is_a?(CacheKey) ? key : CacheKey.new(namespace, key)
    end
  end

  # @rbs! type store[V] = Store::_Store[V]
end
