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
    #: -> either[Error, Snapshot[maybe[V]]]
    def read
      store.read(key)
    end

    # Sets a value in the cache and returns it as an updated snapshot
    #: (V) -> either[Error, Snapshot[V]]
    def write(value)
      store.write(key, value)
    end

    # Deletes the value from the cache and returns the deleted value as a snapshot
    #: -> either[Error, maybe[V]]
    def delete
      store.delete(key)
    end

    # Fetches a value from cache, computing and storing it if not found
    # The snapshot indicates whether the value came from cache or was computed
    #: () { -> V? } -> either[Error, Snapshot[maybe[V]]]
    def fetch(&block)
      store.fetch(key, &block)
    end

    # Checks if the cache contains a value for this key
    #: -> bool
    def present?
      store.read(key).right?
    end

    # Checks if the cache is empty for this key
    #: -> bool
    def empty?
      store.read(key).left?
    end

    # Maps over the cached value if it exists, preserving snapshot metadata
    #: [R] () { (V) -> R } -> either[Error, Snapshot[R]]
    def map(&block)
      read.map { |snapshot| snapshot.map { |mb| mb.map(&block) } }
    end

    # Updates the cached value using the provided block
    # Returns the updated value as a snapshot with source=:updated
    #: () { (V) -> V? } -> either[Error, Snapshot[maybe[V]]]
    def update(&block)
      read.bind do |snapshot|
        new_value = snapshot.value.bind do |value|
          new_value = yield(value)
          Maybe.wrap(new_value)
        end

        if new_value.some?
          write(new_value.value).map do |snapshot|
            snapshot.map { new_value }
          end
        else
          delete.map { snapshot }
        end
      rescue => e
        Either.left(StoreError.new(
          :update,
          key,
          "Failed to update value: #{e.message}",
          e,
        ))
      end
    end

    # Computes and caches a value if the cache is currently empty
    # Returns existing snapshot if present, computed snapshot if cache miss, error otherwise
    #: () { -> V? } -> either[Error, Snapshot[maybe[V]]]
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

    # Convenience method to work with the snapshot directly
    #: [R] () { (Snapshot[V]) -> R } -> either[Error, R]
    def with_snapshot(&block)
      read.map(&block)
    end

    # Convenience method to work with just the value (losing snapshot context)
    #: [R] () { (V) -> R } -> either[Error, R]
    def with(&block)
      read.map { |snapshot| yield(snapshot.value) }
    end

    # @rbs () -> String
    def to_s = "CacheRef(#{key} from #{store.namespace})"

    # @rbs () -> String
    def inspect = "CacheRef(#{key}, #{store.inspect})"
  end
end
