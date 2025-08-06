# typed: strict

module TypedCache
  module Instrumenter
    abstract!

    sig do
      abstract.type_parameters(:R)
        .params(
          event_name: String,
          key: String,
          payload: T::Hash[Symbol, T.untyped],
          blk: T.proc.returns(T.type_parameter(:R)),
        ).returns(T.type_parameter(:R))
    end
    def instrument(event_name, key, **payload, &blk); end

    sig do
      abstract.type_parameters(:R)
        .params(
          event_name: String,
          filters: T::Hash[Symbol, T.untyped],
          blk: T.proc.void,
        ).returns(T.type_parameter(:R))
    end
    def subscribe(event_name, **filters, &blk); end

    sig { overridable.returns(String) }
    def namespace; end

    sig { overridable.returns(T::Boolean) }
    def enabled?; end

    private

    sig { overridable.params(operation: String, key: String, payload: T::Hash[Symbol, T.untyped]).returns(T::Hash[Symbol, T.untyped]) }
    def build_payload(operation, key, **payload); end

    sig(:final) { params(operation: String).returns(String) }
    def event_name(operation); end

    sig(:final) { returns(::TypedCache::Private::Configuration::Instrumentation) }
    def config; end
  end
end
