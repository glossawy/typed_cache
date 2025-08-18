# typed: strict

module TypedCache
  module Store
    extend T::Generic

    abstract!

    CachedType = type_member

    Error = T.type_alias { TypedCache::Error }
    Key = T.type_alias { T.any(String, ::TypedCache::CacheKey) }
    private_constant :Error, :Key

    sig { returns(::TypedCache::Backend[CachedType]) }
    def backend; end

    sig { params(key: Key, kwargs: T::Hash[Symbol, T.untyped]).returns(::TypedCache::Either[Error, ::TypedCache::Snapshot[::TypedCache::Maybe[CachedType]]]) }
    def read(key, **kwargs); end

    sig do
      type_parameters(:K)
        .params(keys: T::Array[T.all(Key, T.type_parameter(:K))], kwargs: T::Hash[Symbol, T.untyped]).returns(::TypedCache::Either[Error, T::Hash[T.all(Key, T.type_parameter(:K)), ::TypedCache::Snapshot[CachedType]]])
    end
    def read_all(keys, **kwargs); end

    sig { params(key: Key, value: CachedType, kwargs: T::Hash[Symbol, T.untyped]).returns(::TypedCache::Either[Error, ::TypedCache::Snapshot[CachedType]]) }
    def write(key, value, **kwargs); end

    sig { params(values: T::Hash[Key, CachedType], kwargs: T::Hash[Symbol, T.untyped]).returns(::TypedCache::Either[Error, T::Array[::TypedCache::Snapshot[CachedType]]]) }
    def write_all(values, **kwargs); end

    sig { params(key: Key).returns(::TypedCache::Either[Error, ::TypedCache::Maybe[CachedType]]) }
    def delete(key); end

    sig { params(key: Key).returns(::TypedCache::CacheRef[CachedType]) }
    def ref(key); end

    sig { void }
    def clear; end

    sig { params(key: Key).returns(T::Boolean) }
    def key?(key); end

    sig do
      type_parameters(:K)
        .params(key: T.all(Key, T.type_parameter(:K)), kwargs: T::Hash[Symbol, T.untyped], block: T.proc.params(key: T.all(Key, T.type_parameter(:K))).returns(T.nilable(CachedType))).returns(::TypedCache::Either[Error, ::TypedCache::Snapshot[::TypedCache::Maybe[CachedType]]])
    end
    def fetch(key, **kwargs, &block); end

    sig do
      type_parameters(:K)
        .params(keys: T::Array[T.all(Key, T.type_parameter(:K))], kwargs: T::Hash[Symbol, T.untyped], block: T.proc.params(key: T.all(Key, T.type_parameter(:K))).returns(T.nilable(CachedType))).returns(::TypedCache::Either[Error, T::Hash[T.all(Key, T.type_parameter(:K)), ::TypedCache::Snapshot[CachedType]]])
    end
    def fetch_all(keys, **kwargs, &block); end

    sig { returns(::TypedCache::Namespace) }
    def namespace; end

    sig { params(ns: T.any(::TypedCache::Namespace, String, T::Array[String])).returns(::TypedCache::Store[CachedType]) }
    def with_namespace(ns); end

    sig { params(ns: T.any(::TypedCache::Namespace, String, T::Array[String])).returns(::TypedCache::Store[CachedType]) }
    def at_namespace(ns); end

    sig do
      type_parameters(:T)
        .params(klass: T::Class[T.type_parameter(:T)], at: T.nilable(T.any(::TypedCache::Namespace, String)))
        .returns(::TypedCache::Store[T.type_parameter(:T)])
    end
    def cache_for(klass, at: T.unsafe(nil)); end
  end
end
