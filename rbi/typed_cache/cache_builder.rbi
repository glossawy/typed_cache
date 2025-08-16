# typed: strict

module TypedCache
  module CacheDefinition
    extend T::Sig
    extend T::Helpers

    InstrumenterSource = T.type_alias { T.any(Symbol, ::TypedCache::Instrumenter) }

    interface!
    sealed!

    sig { abstract.params(name: Symbol, args: T.untyped, options: T::Hash[Symbol, T.anything]).returns(T.all(CacheDefinition, CacheBuilder)) }
    def with_backend(name, *args, **options); end

    sig { abstract.params(name: Symbol, options: T::Hash[Symbol, T.anything]).returns(T.self_type) }
    def with_decorator(name, **options); end

    sig { abstract.params(source: InstrumenterSource).returns(T.self_type) }
    def with_instrumentation(source = T.unsafe(nil)); end
  end

  module CacheBuilder
    extend T::Sig
    extend T::Helpers

    interface!
    sealed!

    sig { abstract.params(namespace: ::TypedCache::Namespace).returns(::TypedCache::Either[Error, ::TypedCache::Store[T.untyped]]) }
    def build(namespace = T.unsafe(nil)); end
  end
end
