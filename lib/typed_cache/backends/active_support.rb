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
      #: (cache_key, **top) -> either[Error, Snapshot[V]]
      def read(key, **kwargs)
        cache_key_str = namespaced_key(key).to_s
        raw_value = cache_store.read(cache_key_str, default_options.merge(**kwargs))
        return Either.left(CacheMissError.new(key)) if raw_value.nil?

        Either.right(Snapshot.cached(key, raw_value))
      rescue => e
        Either.left(StoreError.new(:get, key, "Failed to read from cache: #{e.message}", e))
      end

      # @rbs override
      #: (cache_key, V, **top) -> either[Error, Snapshot[V]]
      def write(key, value, **kwargs)
        cache_key_str = namespaced_key(key).to_s
        success = cache_store.write(cache_key_str, value, default_options.merge(**kwargs))

        if success
          Either.right(Snapshot.cached(key, value))
        else
          Either.left(StoreError.new(:set, key, 'Failed to write to cache', nil))
        end
      rescue => e
        Either.left(StoreError.new(:set, key, "Failed to write to cache: #{e.message}", e))
      end

      # @rbs override
      #: (Hash[cache_key, V], **top) -> either[Error, Array[Snapshot[V]]]
      def write_all(values, **kwargs)
        results = cache_store.write_multi(values.map { |key, value| [namespaced_key(key).to_s, value] }.to_h, default_options.merge(**kwargs))
        Either.right(results.map { |key, value| Snapshot.cached(key, value) })
      rescue => e
        Either.left(StoreError.new(:set_all, values, "Failed to write to cache: #{e.message}", e))
      end

      # @rbs override
      #: (cache_key) -> either[Error, Snapshot[V]]
      def delete(key)
        read(key).fold(
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
      #: (Array[cache_key], **top) -> either[Error, Array[Snapshot[V]]]
      def read_all(keys, **kwargs)
        results = cache_store.read_multi(*keys.map { |key| namespaced_key(key).to_s }, default_options.merge(**kwargs))
        Either.right(results.map { |key, value| [key, Snapshot.cached(key, value)] }.to_h)
      end

      # @rbs override
      #: (Array[cache_key], **top) { (CacheKey) -> V? } -> either[Error, Array[Snapshot[V]]]
      def fetch_all(keys, **kwargs, &block)
        cache_keys = keys.map { |key| namespaced_key(key) }
        key_map = cache_keys.index_by(&:to_s)

        computed_keys = Set.new #: Set[String]
        results = cache_store.fetch_multi(*key_map.keys, default_options.merge(**kwargs)) do |key|
          computed_keys << key
          yield(key_map[key])
        end

        snapshots = [] #: Array[Snapshot[V]]

        results.each do |key, value|
          maybe_value = Maybe.wrap(value)
          snapshots <<
            if computed_keys.include?(key)
              Snapshot.computed(key, maybe_value)
            else
              Snapshot.cached(key, maybe_value)
            end
        end

        Either.right(snapshots)
      rescue StandardError => e
        Either.left(StoreError.new(:fetch_all, keys, "Failed to fetch from cache: #{e.message}", e))
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
