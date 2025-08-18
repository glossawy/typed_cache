# frozen_string_literal: true

module TypedCache
  # Marker mixin for concrete cache back-ends.
  # A Backend *is* a Store, but the reverse is not necessarily true (decorators also
  # include Store). By tagging back-ends with this module we can type-check and
  # register them separately from decorators.
  #
  # Back-ends should *not* assume they wrap another store – they are the leaf nodes
  # that actually persist data.
  # @rbs generic V
  module Backend
    # @rbs! type cache_key = String | CacheKey

    # @rbs!
    #   interface _Backend[V]
    #     def read: (cache_key, **top) -> V?
    #     def read_multi: (Array[cache_key], **top) -> Hash[cache_key, V]
    #     def write: (cache_key, V, **top) -> V
    #     def write_multi: (Hash[cache_key, V], **top) -> Hash[cache_key, V]
    #     def delete: (cache_key, **top) -> V?
    #     def key?: (cache_key) -> bool
    #     def clear: () -> void
    #     def fetch: (cache_key, **top) { () -> V? } -> V?
    #     def fetch_multi: (Array[cache_key], **top) { (cache_key) -> V? } -> Hash[cache_key, V]
    #   end

    # @rbs! include _Backend[V]

    # @rbs override
    # @rbs (cache_key, **top) -> V?
    def read(key, **opts)
      raise NotImplementedError, "#{self.class} must implement #read"
    end

    # @rbs override
    # @rbs (Array[cache_key], **top) -> Hash[cache_key, V]
    def read_multi(keys, **opts)
      keys.to_h { |key| [key, read(key, **opts)] }
    end

    # @rbs override
    # @rbs (cache_key, V, **top) -> V
    def write(key, value, **opts)
      raise NotImplementedError, "#{self.class} must implement #write"
    end

    # @rbs override
    # @rbs (Hash[cache_key, V], **top) -> Hash[cache_key, V]
    def write_multi(values, **opts)
      values.transform_values { |value| write(value, **opts) }
    end

    # @rbs override
    # @rbs (cache_key, **top) -> V?
    def delete(key, **opts)
      raise NotImplementedError, "#{self.class} must implement #delete"
    end

    # @rbs override
    # @rbs (cache_key) -> bool
    def key?(key)
      raise NotImplementedError, "#{self.class} must implement #key?"
    end

    # @rbs override
    # @rbs (**top) -> void
    def clear(**opts)
      raise NotImplementedError, "#{self.class} must implement #clear"
    end

    # @rbs override
    # @rbs (cache_key, **top) { () -> V? } -> V?
    def fetch(key, **opts, &block)
      raise NotImplementedError, "#{self.class} must implement #fetch"
    end

    # @rbs override
    # @rbs (Array[cache_key], **top) { (cache_key) -> V? } -> Hash[cache_key, V]
    def fetch_multi(keys, **opts, &block)
      keys.to_h { |key| [key, fetch(key, **opts, &block)] }
    end
  end

  # @rbs! type backend[V] = Backend::_Backend[V]
end
