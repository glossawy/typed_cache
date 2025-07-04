# frozen_string_literal: true

module TypedCache
  # Decorator that adds instrumentation to any Store implementation
  # This decorator can wrap any store to add ActiveSupport::Notifications
  # @rbs generic V
  class Store::Instrumented # rubocop:disable Style/ClassAndModuleChildren
    include Decorator #[V]

    extend Forwardable

    attr_reader :store #: TypedCache::Store[V]

    class << self
      private

      # @rbs (Symbol, ?operation: String) ?{ (*untyped, **untyped) -> String } -> void
      def instrument(method_name, operation: method_name.to_s, &key_selector)
        define_method(:"#{method_name}_with_instrumentation") do |*args, **kwargs, &block|
          key = key_selector.call(*args, **kwargs) if key_selector # rubocop:disable Performance/RedundantBlockCall

          Instrumentation.instrument(operation, namespace, key || 'n/a', store_type: store_type) do
            send(:"#{method_name}_without_instrumentation", *args, **kwargs, &block)
          end
        end

        alias_method(:"#{method_name}_without_instrumentation", method_name)
        alias_method(method_name, :"#{method_name}_with_instrumentation")
      end
    end

    #: (TypedCache::Store[V]) -> void
    def initialize(store)
      @store = store
    end

    # @rbs override
    #: -> String
    def namespace
      store.namespace
    end

    # @rbs override
    #: -> String
    def store_type
      # Use polymorphism - delegate to the wrapped store
      "instrumented(#{store.store_type})"
    end

    # @rbs override
    #: (cache_key) -> either[Error, CacheRef[V]]
    def ref(key)
      CacheRef.new(self, key)
    end

    # Additional methods that might exist on the wrapped store
    def respond_to_missing?(method_name, include_private = false)
      store.respond_to?(method_name, include_private) || super
    end

    def method_missing(method_name, *args, &block)
      if store.respond_to?(method_name)
        store.send(method_name, *args, &block)
      else
        super
      end
    end

    Store.instance_methods(false).each do |method_name|
      next if instance_methods(false).include?(method_name)

      def_delegator :store, method_name
    end

    # Instrument core operations with proper key extraction
    instrument(:get)    { |key, *_| key }
    instrument(:set)    { |key, *_| key }
    instrument(:delete) { |key, *_| key }
    instrument(:fetch)  { |key, *_| key }
    instrument(:key?)   { |key, *_| key }
    instrument(:clear)  { 'all' }
  end
end
