# typed: strict

module TypedCache
  module Decorator
    extend T::Generic

    include ::TypedCache::Store

    abstract!

    CachedType = type_member

    sig { params(store: ::TypedCache::Store[CachedType]).void }
    def initialize(store); end

    sig { overridable.returns(::TypedCache::Store[CachedType]) }
    def store; end

    sig(:final) { params(key: T.any(String, ::TypedCache::CacheKey)).returns(::TypedCache::CacheRef[CachedType]) }
    def ref(key); end

    sig { overridable.params(key: T.any(String, ::TypedCache::CacheKey)).returns(::TypedCache::Either[Error, ::TypedCache::Snapshot[CachedType]]) }
    def get(key); end

    sig { overridable.params(key: T.any(String, ::TypedCache::CacheKey), value: CachedType).returns(::TypedCache::Either[Error, ::TypedCache::Snapshot[CachedType]]) }
    def set(key, value); end

    sig { overridable.params(key: T.any(String, ::TypedCache::CacheKey)).returns(::TypedCache::Either[Error, ::TypedCache::Snapshot[CachedType]]) }
    def delete(key); end

    sig { overridable.params(key: T.any(String, ::TypedCache::CacheKey)).returns(T::Boolean) }
    def key?(key); end

    sig { overridable.params(key: T.any(String, ::TypedCache::CacheKey), block: T.proc.params(value: CachedType).returns(CachedType)).returns(::TypedCache::Either[Error, ::TypedCache::Snapshot[CachedType]]) }
    def fetch(key, &block); end

    sig { overridable.void }
    def clear; end

    sig(:final) { returns(::TypedCache::Namespace) }
    def namespace; end

    sig(:final) { params(namespace: ::TypedCache::Namespace).returns(::TypedCache::Store[CachedType]) }
    def with_namespace(namespace); end

    sig { abstract.returns(String) }
    def store_type; end

    sig { overridable.params(other: T.self_type).void }
    def initialize_copy(other); end

    sig(:final) { params(key: T.any(String, ::TypedCache::CacheKey)).returns(::TypedCache::CacheKey) }
    def namespaced_key(key); end

    sig { overridable.returns(::TypedCache::Instrumenter) }
    def instrumenter; end
  end
end
