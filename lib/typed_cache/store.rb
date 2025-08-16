# frozen_string_literal: true

module TypedCache
  # @rbs!
  #

  # Generic interface for type-safe cache storage implementations
  # All stores are assumed to handle namespacing internally
  #
  # This interface follows the Command-Query Separation principle:
  # - Commands (set, delete, clear) perform actions and may return results
  # - Queries (get, key?, fetch) ask questions without side effects
  #
  # @rbs generic V
  module Store
    # @rbs! type cache_key = String | CacheKey

    # @rbs!
    #   interface _Store[V]
    #     def read: (cache_key) -> either[Error, Snapshot[V]]
    #     def read_all: (Array[cache_key]) -> either[Error, Array[Snapshot[V]]]
    #     def ref: (cache_key) -> CacheRef[V]
    #     def write: (cache_key, V) -> either[Error, Snapshot[V]]
    #     def write_all: (Hash[cache_key, V]) -> either[Error, Array[Snapshot[V]]]
    #     def delete: (cache_key) -> either[Error, Snapshot[V]]
    #     def key?: (cache_key) -> bool
    #     def clear: () -> maybe[Error]
    #     def fetch: (cache_key) { () -> V? } -> either[Error, Snapshot[maybe[V]]]
    #     def fetch_all: (Array[cache_key]) { (CacheKey) -> V? } -> either[Error, Array[Snapshot[V]]]
    #     def namespace: () -> Namespace
    #     def with_namespace: (Namespace) -> Store[V]
    #     def store_type: () -> String
    #   end
    #   include _Store[V]

    # @rbs!
    #   interface _Decorator[V]
    #     def initialize: (Store[V]) -> void
    #   end

    # @rbs (Store[V]) -> void
    def initialize_copy(other)
      super
      @namespace = other.namespace
    end

    # Retrieves a value from the cache
    # @rbs (cache_key, **top) -> either[Error, Snapshot[V]]
    def read(key, **kwargs)
      Either.left(NotImplementedError.new("#{self.class} must implement #read"))
    end

    # @rbs (Array[cache_key], **top) -> either[Error, Hash[cache_key, Snapshot[V]]]
    def read_all(keys, **kwargs)
      keys.map { |key| read(key, **kwargs) }.reduce(Either.right({})) do |acc, result|
        acc.bind do |values|
          result.map { |value| values.merge(value.key => value) }
        end
      end
    end

    # Retrieves a cache reference for a key
    # @rbs (cache_key) -> CacheRef[V]
    def ref(key)
      CacheRef.new(self, namespaced_key(key))
    end

    # Stores a value in the cache
    # @rbs (cache_key, V, **top) -> either[Error, Snapshot[V]]
    def write(key, value, **kwargs)
      Either.left(NotImplementedError.new("#{self.class} must implement #write"))
    end

    # @rbs (Hash[cache_key, V], **top) -> either[Error, Hash[cache_key, Snapshot[V]]]
    def write_all(values, **kwargs)
      values.map { |key, value| write(key, value, **kwargs) }.reduce(Either.right({})) do |acc, result|
        acc.bind do |values|
          result.map { |value| values.merge(value.key => value) }
        end
      end
    end

    # Removes a value from the cache, returning the removed value
    # @rbs (cache_key) -> either[Error, Snapshot[V]]
    def delete(key)
      Either.left(NotImplementedError.new("#{self.class} must implement #delete"))
    end

    # Checks if a key exists in the cache (query operation)
    # @rbs (cache_key) -> bool
    def key?(key)
      false # Safe default - assume key doesn't exist
    end

    # Clears all values from the cache namespace (command operation)
    # @rbs () -> maybe[Error]
    def clear
      Maybe.some(NotImplementedError.new("#{self.class} does not implement #clear"))
    end

    # Fetches a value from cache, computing and storing it if not found
    # This is an atomic operation that combines read and write
    # @rbs (cache_key, **top) { () -> V } -> either[Error, Snapshot[V]]
    def fetch(key, **kwargs, &block)
      # Default implementation using read/write pattern
      read_result = read(key)
      return read_result if read_result.right?

      # Only proceed if it's a cache miss
      return read_result unless read_result.error.is_a?(CacheMissError)

      # Compute and store new value
      begin
        computed_value = yield
        write(key, computed_value, **kwargs)
        Either.right(Snapshot.computed(key, computed_value))
      rescue => e
        Either.left(StoreError.new(:fetch, key, "Failed to compute value for key '#{key}': #{e.message}", e))
      end
    end

    # @rbs (Array[cache_key], **top) { (CacheKey) -> V } -> either[Error, Array[Snapshot[V]]]
    def fetch_all(keys, **kwargs, &block)
      keys = keys.map { |key| namespaced_key(key) }
      keys.reduce(Either.right([])) do |acc, key|
        acc.bind do |values|
          fetch(key, **kwargs) { yield(key) }.map { |value| values + [value] }
        end
      end
    end

    # @rbs () -> Instrumenter
    def instrumenter = Instrumenters::Null.instance

    # Returns the namespace for this store (for instrumentation/debugging)
    # @rbs () -> Namespace
    def namespace
      raise NotImplementedError, "#{self.class} must implement #namespace"
    end

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

    # Returns the store type identifier for instrumentation/debugging
    # @rbs () -> String
    def store_type
      snake_case(self.class.name.split('::').last)
    end

    protected

    attr_writer :namespace #: Namespace

    private

    #: (String) -> String
    def snake_case(string)
      string
        .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
        .gsub(/([a-z\d])([A-Z])/, '\1_\2')
        .tr('-', '_')
        .downcase
    end

    #: (cache_key) -> CacheKey
    def namespaced_key(key)
      key.is_a?(CacheKey) ? key : CacheKey.new(namespace, key)
    end
  end

  # @rbs! type backend[V] = Store::_Store[V]
  # @rbs! type decorator[V] = backend[V] & Store::_Decorator[V]
  # @rbs! type store[V] = backend[V] | decorator[V]
end
