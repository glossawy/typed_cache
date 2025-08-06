# frozen_string_literal: true

require 'forwardable'

module TypedCache
  # Marker mixin for cache store decorators. A decorator behaves exactly like a
  # Store but must accept another Store instance in its constructor.
  # @rbs generic V
  module Decorator
    extend Forwardable

    include Store #[V]
    # @rbs! include Store::_Store[V]
    # @rbs! include Store::_Decorator[V]

    # @rbs!
    #  def store: -> Store[V]

    Store.instance_methods(false).each do |method_name|
      def_delegator :store, method_name
    end

    # @rbs override
    #: (cache_key) -> either[Error, CacheRef[V]]
    def ref(key)
      CacheRef.new(self, key)
    end

    # @rbs override
    #: (self) -> void
    def initialize_copy(other)
      super

      @store = other.store.clone
    end
  end
end
