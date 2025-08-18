# frozen_string_literal: true

require 'singleton'

require 'concurrent/map'

module TypedCache
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

        class << self
          # @rbs (value: V, expires_in: Integer) -> Entry[V]
          def expiring(value:, expires_in:)
            new(value: value, expires_at: Clock.moment + expires_in)
          end
        end

        # @rbs () -> bool
        def expired?
          Clock.now >= expires_at
        end
      end
      private_constant :Entry

      attr_reader :ttl #: Integer
      attr_reader :backing_store #: hash_like[String, Entry[V]]

      #: (ttl: Integer) -> void
      def initialize(ttl: 600)
        @ttl = ttl
        @backing_store = Concurrent::Map.new
      end

      # @rbs override
      #: (cache_key, **top) -> V?
      def read(key, **kwargs)
        purge_expired_keys

        entry = backing_store[key]
        entry&.value
      end

      # @rbs override
      #: (cache_key, V, expires_in: Integer, expires_at: Time, **top) -> V
      def write(key, value, expires_in: @ttl, expires_at: Clock.now + expires_in, **kwargs)
        entry = Entry.new(value: value, expires_at: expires_at)
        backing_store[key] = entry
        value
      end

      # @rbs override
      #: (cache_key) -> V?
      def delete(key)
        entry = backing_store.delete(key)
        entry&.value
      end

      # @rbs override
      #: (cache_key) -> bool
      def key?(key)
        return false unless backing_store.key?(key)

        entry = backing_store[key]
        !entry.expired?
      end

      # @rbs override
      #: -> void
      def clear
        backing_store.clear
      end

      # @rbs override
      #: (cache_key, ttl: Integer, **top) { () -> V? } -> V?
      def fetch(key, ttl: @ttl, **opts, &block)
        purge_expired_keys
        result = backing_store.compute_if_absent(key) do
          Entry.new(value: yield(key), expires_at: Clock.now + ttl)
        end

        result.value
      end

      private

      #: -> void
      def purge_expired_keys
        backing_store.each do |key, entry|
          backing_store.delete(key) if entry.expired?
        end
      end
    end
  end
end
