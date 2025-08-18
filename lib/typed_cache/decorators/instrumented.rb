# frozen_string_literal: true

module TypedCache
  # Decorator that adds instrumentation to any Store implementation
  # This decorator can wrap any store to add ActiveSupport::Notifications
  # @rbs generic V
  class Decorators::Instrumented # rubocop:disable Style/ClassAndModuleChildren
    include Decorator #[V]

    extend Forwardable

    attr_reader :backend #: Backend[V]
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
            return #{alias_prefix}_without_instrumentation(...) if @in_instrumentation

            key = #{alias_prefix}_instrumentation_key(...)
            instrumenter.instrument(:"#{operation}", key) do
              @in_instrumentation = true

              #{alias_prefix}_without_instrumentation(...)
            ensure
              @in_instrumentation = false
            end
          end
        RUBY

        alias_method(:"#{alias_prefix}_without_instrumentation", method_name)
        alias_method(method_name, :"#{alias_prefix}_with_instrumentation")
      end
    end

    #: (Backend[V], instrumenter: Instrumenter) -> void
    def initialize(backend, instrumenter:)
      @backend = backend
      @instrumenter = instrumenter

      # Avoid instrumenting the cache calls themselves, fetch_all may call fetch for example
      @in_instrumentation = false
    end

    # @rbs override
    #: (self) -> self
    def initialize_copy(other)
      super
      @instrumenter = other.instrumenter
    end

    # Additional methods that might exist on the wrapped store
    def respond_to_missing?(method_name, include_private = false)
      backend.respond_to?(method_name, include_private) || super
    end

    def method_missing(method_name, *args, &block)
      if backend.respond_to?(method_name)
        backend.send(method_name, *args, &block)
      else
        super
      end
    end

    # Instrument core operations with proper key extraction
    instrument(:read) { |key, *_| key }
    instrument(:read_multi) { |keys, *_| keys.map(&:to_s).join('_') }
    instrument(:write) { |key, *_| key }
    instrument(:write_multi) { |values, *_| values.map { |key, _| key.to_s }.join('_') }
    instrument(:delete) { |key, *_| key }
    instrument(:fetch)  { |key, *_| key }
    instrument(:fetch_multi) { |keys, *_| keys.map(&:to_s).join('_') }
    instrument(:key?)   { |key, *_| key }
    instrument(:clear)  { 'all' }
  end
end
