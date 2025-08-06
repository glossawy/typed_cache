# frozen_string_literal: true

require_relative 'cache_key'
require_relative 'store'
require_relative 'snapshot'

module TypedCache
  # A monadic wrapper for cached values that provides safe access with rich error context.
  # All operations return Either[Error, Snapshot[V]] to provide detailed information about
  # cache operations and the source of values.
  #
  # @rbs generic V
  class CacheRef
    attr_reader :store #: Store[V]
    attr_reader :key #: CacheKey

    #: (Store[V], CacheKey) -> void
    def initialize(store, key)
      @store = store
      @key = key
    end

    # Gets a value from the cache as a snapshot
    #: -> either[Error, Snapshot[V]]
    def get
      store.get(key)
    end

    # Sets a value in the cache and returns it as an updated snapshot
    #: (V) -> either[Error, Snapshot[V]]
    def set(value)
      store.set(key, value)
    end

    # Deletes the value from the cache and returns the deleted value as a snapshot
    #: -> either[Error, Snapshot[V]]
    def delete
      store.delete(key)
    end

    # Fetches a value from cache, computing and storing it if not found
    # The snapshot indicates whether the value came from cache or was computed
    #: () { -> V } -> either[Error, Snapshot[V]]
    def fetch(&block)
      store.fetch(key, &block)
    end

    # Checks if the cache contains a value for this key
    #: -> bool
    def present?
      store.get(key).right?
    end

    # Checks if the cache is empty for this key
    #: -> bool
    def empty?
      store.get(key).left?
    end

    # Maps over the cached value if it exists, preserving snapshot metadata
    #: [R] () { (V) -> R } -> either[Error, Snapshot[R]]
    def map(&block)
      get.map { |snapshot| snapshot.map(&block) }
    end

    # Binds over the cached value, allowing for monadic composition with snapshots
    #: [R] () { (V) -> either[Error, R] } -> either[Error, Snapshot[R]]
    def bind(&block)
      get.bind { |snapshot| snapshot.bind(&block) }
    end

    alias flat_map bind

    # Updates the cached value using the provided block
    # Returns the updated value as a snapshot with source=:updated
    #: () { (V) -> V } -> either[Error, Snapshot[V]]
    def update(&block)
      get.bind do |snapshot|
        new_value = yield(snapshot.value)
        set(new_value)
      rescue => e
        Either.left(StoreError.new(
          :update,
          key,
          "Failed to update value: #{e.message}",
          e,
        ))
      end
    end

    # Returns the cached value or a default if the cache is empty/errored
    #: (V) -> V
    def value_or(default)
      get.fold(
        ->(_error) { default },
        ->(snapshot) { snapshot.value },
      )
    end

    # Returns a Maybe containing the cached value, or None if not present
    # This provides a more functional approach than value_or
    #: -> maybe[V]
    def value_maybe
      get.fold(
        ->(_error) { Maybe.none },
        ->(snapshot) { Maybe.some(snapshot.value) },
      )
    end

    # Computes and caches a value if the cache is currently empty
    # Returns existing snapshot if present, computed snapshot if cache miss, error otherwise
    #: () { -> V } -> either[Error, Snapshot[V]]
    def compute_if_absent(&block)
      fetch(&block).fold(
        ->(error) {
          Either.left(StoreError.new(
            :compute_if_absent,
            key,
            "Failed to compute value: #{error.message}",
            error,
          ))
        },
        ->(snapshot) { Either.right(snapshot) },
      )
    end

    # Creates a new CacheRef with the same store but different key
    #: [R] (String) -> CacheRef[R]
    def with_key(new_key)
      CacheRef.new(store, store.namespace.key(new_key))
    end

    # Creates a scoped CacheRef by appending to the current key path
    #: [R] (String) -> CacheRef[R]
    def scope(scope_key)
      new_namespace = store.namespace.nested(key.key)
      new_store = store.with_namespace(new_namespace)
      CacheRef.new(new_store, new_namespace.key(scope_key))
    end

    # Pattern matching support for Either[Error, Snapshot[V]] results
    #: [R] () { (Error) -> R } () { (Snapshot[V]) -> R } -> R
    def fold(left_fn, right_fn)
      get.fold(left_fn, right_fn)
    end

    # Convenience method to work with the snapshot directly
    #: [R] () { (Snapshot[V]) -> R } -> either[Error, R]
    def with_snapshot(&block)
      get.map(&block)
    end

    # Convenience method to work with just the value (losing snapshot context)
    #: [R] () { (V) -> R } -> either[Error, R]
    def with(&block)
      get.map { |snapshot| yield(snapshot.value) }
    end
  end
end
