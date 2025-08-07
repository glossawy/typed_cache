# typed: strict

module TypedCache
  class CacheBuilder
    Config = T.type_alias { ::TypedCache::Private::Configuration }
    InstrumenterSource = T.type_alias { T.any(Symbol, ::TypedCache::Instrumenter) }

    private_constant :Config, :InstrumenterSource

    sig { params(namespace: ::TypedCache::Namespace).returns(::TypedCache::Either[Error, ::TypedCache::Store[T.anything]]) }
    def build(namespace = T.unsafe(nil)); end

    sig { params(name: Symbol, args: T.untyped, options: T::Hash[Symbol, T.anything]).returns(T.self_type) }
    def with_backend(name, *args, **options); end

    sig { params(name: Symbol, options: T::Hash[Symbol, T.anything]).returns(T.self_type) }
    def with_decorator(name, **options); end

    sig { params(source: InstrumenterSource).returns(T.self_type) }
    def with_instrumentation(source); end
  end
end
