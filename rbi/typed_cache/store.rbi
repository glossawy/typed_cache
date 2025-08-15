# typed: strict

module TypedCache
  module Store
    extend T::Generic

    abstract!

    CachedType = type_member

    Error = T.type_alias { TypedCache::Error }
    Key = T.type_alias { T.any(String, ::TypedCache::CacheKey) }
    private_constant :Error, :Key

    sig { params(key: Key).returns(::TypedCache::Either[Error, CachedType]) }
    def read(key); end

    sig { params(keys: T::Array[Key]).returns(::TypedCache::Either[Error, T::Array[::TypedCache::Snapshot[CachedType]]]) }
    def read_all(keys); end

    sig { params(key: Key, value: CachedType).returns(::TypedCache::Either[Error, ::TypedCache::Snapshot[CachedType]]) }
    def write(key, value); end

    sig { params(values: T::Hash[Key, CachedType]).returns(::TypedCache::Either[Error, T::Array[::TypedCache::Snapshot[CachedType]]]) }
    def write_all(values); end

    sig { params(key: Key).returns(::TypedCache::Either[Error, ::TypedCache::Snapshot[CachedType]]) }
    def delete(key); end

    sig { params(key: Key).returns(::TypedCache::CacheRef[CachedType]) }
    def ref(key); end

    sig { void }
    def clear; end

    sig { params(key: Key).returns(T::Boolean) }
    def key?(key); end

    sig { params(key: Key, block: T.proc.returns(T.nilable(CachedType))).returns(::TypedCache::Either[Error, ::TypedCache::Snapshot[::TypedCache::Maybe[CachedType]]]) }
    def fetch(key, &block); end

    sig { params(keys: T::Array[Key], block: T.proc.params(key: ::TypedCache::CacheKey).returns(T.nilable(CachedType))).returns(::TypedCache::Either[Error, T::Array[::TypedCache::Snapshot[CachedType]]]) }
    def fetch_all(keys, &block); end

    sig { returns(::TypedCache::Namespace) }
    def namespace; end

    sig { params(ns: T.any(::TypedCache::Namespace, String, T::Array[String])).returns(::TypedCache::Store[CachedType]) }
    def with_namespace(ns); end

    sig { returns(String) }
    def store_type; end

    sig { returns(T.self_type) }
    def clone; end

    sig { params(key: Key).returns(::TypedCache::CacheKey) }
    def namespaced_key(key); end

    sig { returns(::TypedCache::Instrumenter) }
    def instrumenter; end

    protected

    sig { params(string: String).returns(String) }
    def snake_case(string); end

    sig { params(namespace: ::TypedCache::Namespace).returns(::TypedCache::Namespace) }
    def nested_namespace(namespace); end
  end
end
