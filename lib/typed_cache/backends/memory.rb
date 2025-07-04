# frozen_string_literal: true

require 'singleton'
require 'forwardable'

module TypedCache
  class MemoryStoreRegistry
    include Singleton
    extend Forwardable

    def_delegators :@backing_store, :[], :[]=, :delete, :key?, :keys

    #: -> void
    def initialize
      @backing_store = Concurrent::Map.new
    end
  end

  module Backends
    # A type-safe memory store implementation with built-in namespacing
    # @rbs generic V
    class Memory
      include Backend #[V]

      # @rbs!
      #   interface _HashLike[K, V]
      #     def []: (K) -> V?
      #     def []=: (K, V) -> V
      #     def delete: (K) -> V?
      #     def key?: (K) -> bool
      #     def keys: () -> Array[K]
      #   end
      #
      #   type hash_like[K, V] = _HashLike[K, V]

      # @private
      # @rbs generic V
      class Entry < Dry::Struct
        attribute :value, Dry.Types::Any
        attribute :expires_at, Dry.Types::Time

        # @rbs! attr_accessor expires_at: Time
        # @rbs! attr_reader value: V

        # @rbs (value: V, expires_in: Integer) -> Entry[V]
        def self.expiring(value:, expires_in:)
          new(value: value, expires_at: Clock.moment + expires_in)
        end

        # @rbs () -> bool
        def expired?
          Clock.moment >= expires_at
        end
      end
      private_constant :Entry

      attr_reader :namespace, :ttl #: Namespace, Integer
      attr_reader :backing_store #: hash_like[CacheKey, Entry[V]]

      #: (Namespace, shared: bool, ttl: Integer) -> void
      def initialize(namespace, shared: false, ttl: 600)
        @namespace = namespace
        @ttl = ttl
        @backing_store = shared ? MemoryStoreRegistry.instance : {}
      end

      # @rbs override
      #: (cache_key) -> either[Error, Snapshot[V]]
      def get(key)
        key = namespaced_key(key)
        return Either.left(CacheMissError.new(key)) unless backing_store.key?(key)

        entry = backing_store[key]

        if entry.expired?
          backing_store.delete(key)
          return Either.left(CacheMissError.new(key))
        end

        Either.right(Snapshot.new(entry.value, source: :cache))
      end

      # @rbs override
      #: (cache_key, V) -> either[Error, Snapshot[V]]
      def set(key, value)
        key = namespaced_key(key)
        expires_at = Clock.moment + @ttl
        entry = Entry.new(value: value, expires_at: expires_at)
        backing_store[key] = entry
        Either.right(Snapshot.new(value, source: :cache))
      rescue => e
        Either.left(StoreError.new(
          :set,
          key,
          "Failed to store value for key '#{key}': #{e.message}",
          e,
        ))
      end

      # @rbs override
      #: (cache_key) -> either[Error, Snapshot[V]]
      def delete(key)
        key = namespaced_key(key)
        entry = backing_store.delete(key)
        if entry.nil?
          Either.left(CacheMissError.new(key))
        else
          Either.right(Snapshot.new(entry.value, source: :cache))
        end
      end

      # @rbs override
      #: (cache_key) -> bool
      def key?(key)
        key = namespaced_key(key)
        return false unless backing_store.key?(key) && key.belongs_to?(namespace)

        entry = backing_store[key]
        !entry.expired?
      end

      # @rbs override
      #: -> maybe[Error]
      def clear
        keys_to_delete = backing_store.keys.select { |k| k.belongs_to?(namespace) }
        keys_to_delete.each { |key| backing_store.delete(key) }
        Maybe.none
      rescue => e
        Maybe.some(e)
      end

      # @rbs override
      #: -> String
      def store_type
        'memory'
      end

      #: -> Integer
      def size
        purge_expired_keys
        backing_store.keys.count { |k| k.belongs_to?(namespace) }
      end

      #: -> Array[CacheKey]
      def keys
        purge_expired_keys
        backing_store.keys
          .select { |k| k.belongs_to?(namespace) }
      end

      private

      def namespaced_entries
        backing_store.select { |key, _entry| key.belongs_to?(namespace) }
      end

      def purge_expired_keys
        namespaced_entries.each do |key, entry|
          backing_store.delete(key) if entry.expired?
        end
      end
    end
  end
end
