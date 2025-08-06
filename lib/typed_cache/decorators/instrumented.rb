# frozen_string_literal: true

module TypedCache
  # Decorator that adds instrumentation to any Store implementation
  # This decorator can wrap any store to add ActiveSupport::Notifications
  # @rbs generic V
  class Decorators::Instrumented # rubocop:disable Style/ClassAndModuleChildren
    include Decorator #[V]

    extend Forwardable

    attr_reader :store #: TypedCache::Store[V]
    attr_reader :instrumenter #: Instrumenter

    class << self
      private

      # @rbs (Symbol, ?operation: String) ?{ (*untyped, **untyped) -> String } -> void
      def instrument(method_name, operation: method_name.to_s, &key_selector)
        key_selector ||= ->(*_args, **_kwargs, &_block) { 'n/a' }
        alias_prefix = method_name.to_s.delete('?!')

        define_method(:"#{alias_prefix}_instrumentation_key", &key_selector)

        class_eval(<<~RUBY, __FILE__, __LINE__ + 1)
          def #{alias_prefix}_with_instrumentation(...)
            key = #{alias_prefix}_instrumentation_key(...)
            instrumenter.instrument(:"#{operation}", key, store_type: store_type) do
              #{alias_prefix}_without_instrumentation(...)
            end
          end
        RUBY

        alias_method(:"#{alias_prefix}_without_instrumentation", method_name)
        alias_method(method_name, :"#{alias_prefix}_with_instrumentation")
      end
    end

    #: (TypedCache::Store[V], instrumenter: Instrumenter) -> void
    def initialize(store, instrumenter:)
      @store = store
      @instrumenter = instrumenter
    end

    # @rbs override
    #: (self) -> self
    def initialize_copy(other)
      super
      @instrumenter = other.instrumenter
    end

    # @rbs override
    #: -> String
    def store_type
      # Use polymorphism - delegate to the wrapped store
      "instrumented(#{store.store_type})"
    end

    # @rbs override
    # @rbs (key) -> CacheRef[V]
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

    # Instrument core operations with proper key extraction
    instrument(:get)    { |key, *_| key }
    instrument(:set)    { |key, *_| key }
    instrument(:delete) { |key, *_| key }
    instrument(:fetch)  { |key, *_| key }
    instrument(:key?)   { |key, *_| key }
    instrument(:clear)  { 'all' }
  end
end
