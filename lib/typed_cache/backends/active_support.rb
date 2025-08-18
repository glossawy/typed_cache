# frozen_string_literal: true

module TypedCache
  module Backends
    # Adapter that wraps any ActiveSupport::Cache::Store to work with TypedCache
    # @rbs generic V
    class ActiveSupport
      include Backend #[V]

      attr_reader :cache_store #: ::ActiveSupport::Cache::Store
      attr_reader :default_options #: Hash[Symbol, top]

      #: (::ActiveSupport::Cache::Store, ?Hash[Symbol, top]) -> void
      def initialize(cache_store, default_options = {})
        @cache_store = cache_store
        @default_options = default_options
      end

      # @rbs override
      #: (cache_key, **top) -> V?
      def read(key, **kwargs)
        cache_store.read(key, default_options.merge(kwargs))
      end

      # @rbs override
      #: (cache_key, V, **top) -> V
      def write(key, value, **kwargs)
        cache_store.write(key, value, default_options.merge(kwargs))
      end

      # @rbs override
      #: (Hash[cache_key, V], **top) -> Array[V]
      def write_all(values, **kwargs)
        cache_store.write_multi(values, default_options.merge(kwargs))
      end

      # @rbs override
      #: (cache_key) -> V?
      def delete(key)
        cache_store.delete(key, default_options)
      end

      # @rbs override
      #: (Array[cache_key], **top) -> Hash[cache_key, V]
      def read_all(keys, **kwargs)
        cache_store.read_multi(*keys, default_options.merge(kwargs))
      end

      # @rbs override
      #: (cache_key, **top) { () -> V? } -> V?
      def fetch(key, **kwargs, &block)
        cache_store.fetch(key, default_options.merge(kwargs), &block)
      end

      # @rbs override
      #: (Array[cache_key], **top) { (CacheKey) -> V? } -> Hash[cache_key, V]
      def fetch_all(keys, **kwargs, &block)
        cache_store.fetch_multi(*keys, default_options.merge(kwargs), &block)
      end

      # @rbs override
      #: (cache_key) -> bool
      def key?(key)
        cache_store.exist?(key, default_options)
      end

      # @rbs override
      #: -> void
      def clear
        cache_store.clear(default_options)
      end

      #: (Hash[Symbol, top]) -> ActiveSupport[V]
      def with_options(new_options)
        self.class.new(cache_store, new_options)
      end

      #: -> ::ActiveSupport::Cache::Store
      def raw_cache
        cache_store
      end
    end
  end
end
