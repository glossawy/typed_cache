# typed: strict

module TypedCache
  module Decorator
    include ::TypedCache::Store

    abstract!

    V = type_member

    sig { params(store: ::TypedCache::Store[V]).void }
    def initialize(store); end

    sig { overridable.returns(::TypedCache::Store[V]) }
    def store; end

    sig(:final) { params(key: T.any(String, ::TypedCache::CacheKey)).returns(::TypedCache::CacheRef[V]) }
    def ref(key); end

    sig { overridable.params(key: T.any(String, ::TypedCache::CacheKey)).returns(::TypedCache::Either[Error, ::TypedCache::Snapshot[V]]) }
    def get(key); end

    sig { overridable.params(key: T.any(String, ::TypedCache::CacheKey), value: V).returns(::TypedCache::Either[Error, ::TypedCache::Snapshot[V]]) }
    def set(key, value); end

    sig { overridable.params(key: T.any(String, ::TypedCache::CacheKey)).returns(::TypedCache::Either[Error, ::TypedCache::Snapshot[V]]) }
    def delete(key); end

    sig { overridable.params(key: T.any(String, ::TypedCache::CacheKey)).returns(T::Boolean) }
    def key?(key); end

    sig { overridable.params(key: T.any(String, ::TypedCache::CacheKey), block: T.proc.params(value: V).returns(V)).returns(::TypedCache::Either[Error, ::TypedCache::Snapshot[V]]) }
    def fetch(key, &block); end

    sig { overridable.void }
    def clear; end

    sig(:final) { returns(::TypedCache::Namespace) }
    def namespace; end

    sig(:final) { params(namespace: ::TypedCache::Namespace).returns(::TypedCache::Store[V]) }
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
