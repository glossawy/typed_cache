# frozen_string_literal: true

module TypedCache
  module Backends
    # Adapter that wraps any ActiveSupport::Cache::Store to work with TypedCache
    # @rbs generic V
    class ActiveSupport
      include Backend #[V]

      attr_reader :namespace #: Namespace
      attr_reader :cache_store #: ::ActiveSupport::Cache::Store
      attr_reader :default_options #: Hash[Symbol, top]

      #: (Namespace, ::ActiveSupport::Cache::Store, ?Hash[Symbol, top]) -> void
      def initialize(namespace, cache_store, default_options = {})
        @namespace = namespace
        @cache_store = cache_store
        @default_options = default_options
      end

      # @rbs override
      #: (cache_key) -> either[Error, Snapshot[V]]
      def get(key)
        cache_key_str = namespaced_key(key).to_s
        raw_value = cache_store.read(cache_key_str, default_options)
        return Either.left(CacheMissError.new(key)) if raw_value.nil?

        Either.right(Snapshot.new(raw_value, source: :cache))
      rescue => e
        Either.left(StoreError.new(:get, key, "Failed to read from cache: #{e.message}", e))
      end

      # @rbs override
      #: (cache_key, V) -> either[Error, Snapshot[V]]
      def set(key, value)
        cache_key_str = namespaced_key(key).to_s
        success = cache_store.write(cache_key_str, value, default_options)

        if success
          Either.right(Snapshot.new(value, source: :cache))
        else
          Either.left(StoreError.new(:set, key, 'Failed to write to cache', nil))
        end
      rescue => e
        Either.left(StoreError.new(:set, key, "Failed to write to cache: #{e.message}", e))
      end

      # @rbs override
      #: (cache_key) -> either[Error, Snapshot[V]]
      def delete(key)
        get(key).fold(
          ->(error) { Either.left(error) },
          ->(snapshot) {
            cache_key_str = namespaced_key(key).to_s
            cache_store.delete(cache_key_str, default_options)
            Either.right(snapshot)
          },
        )
      rescue => e
        Either.left(StoreError.new(:delete, key, "Failed to delete from cache: #{e.message}", e))
      end

      # @rbs override
      #: (cache_key) -> bool
      def key?(key)
        cache_store.exist?(namespaced_key(key).to_s, default_options)
      rescue => _e
        false
      end

      # @rbs override
      #: -> maybe[Error]
      def clear
        if cache_store.respond_to?(:delete_matched)
          namespace_prefix_patterns.each do |pattern|
            cache_store.delete_matched(pattern, default_options)
          end
        elsif cache_store.respond_to?(:clear)
          cache_store.clear(default_options)
        end
        Maybe.none
      rescue => e
        Maybe.some(e)
      end

      # @rbs override
      #: -> String
      def store_type
        'active_support'
      end

      #: (Hash[Symbol, top]) -> ActiveSupport[V]
      def with_options(new_options)
        self.class.new(namespace, cache_store, new_options)
      end

      #: -> ::ActiveSupport::Cache::Store
      def raw_cache
        cache_store
      end

      private

      # Regex patterns that match keys for this namespace (with trailing colon)
      #: -> Array[Regexp]
      def namespace_prefix_patterns
        [
          /\A#{Regexp.escape(namespace.to_s)}:/,
        ]
      end
    end
  end
end
