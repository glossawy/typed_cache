# frozen_string_literal: true

module TypedCache
  # Immutable snapshot of a cached value with metadata about its source and age
  # @rbs generic V
  class Snapshot
    attr_reader :key #: CacheKey
    attr_reader :value #: V
    attr_reader :retrieved_at #: Time
    attr_reader :source #: Symbol

    #: (CacheKey, V, source: Symbol, retrieved_at: Time) -> void
    def initialize(key, value, source:, retrieved_at: Time.now)
      @key = key
      @value = value
      @retrieved_at = retrieved_at
      @source = source
    end

    # Age of the snapshot in seconds
    #: -> Float
    def age
      Time.now - retrieved_at
    end

    # Whether this value came from cache
    #: -> bool
    def from_cache?
      source == :cache
    end

    # Whether this value was freshly computed
    #: -> bool
    def computed?
      source == :computed
    end

    # Whether this value was updated
    #: -> bool
    def updated?
      source == :updated
    end

    # Map over the value while preserving snapshot metadata
    #: [R] () { (V) -> R } -> Snapshot[R]
    def map(&block)
      new_value = yield(value)
      Snapshot.new(key, new_value, source: source, retrieved_at: retrieved_at)
    end

    # Bind over the value with Either error handling
    #: [R] () { (V) -> either[Error, R] } -> either[Error, Snapshot[R]]
    def bind(&block)
      result = yield(value)
      result.map { |new_value| Snapshot.new(key, new_value, source: source, retrieved_at: retrieved_at) }
    end

    alias flat_map bind

    class << self
      # Creates a snapshot for a cached value
      #: [V] (CacheKey, V) -> Snapshot[V]
      def cached(key, value)
        new(key, value, source: :cache)
      end

      # Creates a snapshot for a computed value
      #: [V] (CacheKey, V) -> Snapshot[V]
      def computed(key, value)
        new(key, value, source: :computed)
      end

      # Creates a snapshot for an updated value
      #: [V] (CacheKey, V) -> Snapshot[V]
      def updated(key, value)
        new(key, value, source: :updated)
      end
    end
  end
end
