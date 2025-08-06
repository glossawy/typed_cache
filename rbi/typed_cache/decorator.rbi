# typed: strict

module TypedCache
  module Decorator
    include Store

    abstract!

    V = type_member

    sig { params(store: Store[V]).void }
    def initialize(store); end

    sig { overridable.returns(Store[V]) }
    def store; end

    sig(:final) { params(key: T.any(String, CacheKey)).returns(CacheRef[V]) }
    def ref(key); end

    sig { overridable.params(key: T.any(String, CacheKey)).returns(Either[Error, Snapshot[V]]) }
    def get(key); end

    sig { overridable.params(key: T.any(String, CacheKey), value: V).returns(Either[Error, Snapshot[V]]) }
    def set(key, value); end

    sig { overridable.params(key: T.any(String, CacheKey)).returns(Either[Error, Snapshot[V]]) }
    def delete(key); end

    sig { overridable.params(key: T.any(String, CacheKey)).returns(T::Boolean) }
    def key?(key); end

    sig { overridable.params(key: T.any(String, CacheKey), block: T.proc.params(value: V).returns(V)).returns(Either[Error, Snapshot[V]]) }
    def fetch(key, &block); end

    sig { overridable.void }
    def clear; end

    sig(:final) { returns(Namespace) }
    def namespace; end

    sig(:final) { params(namespace: Namespace).returns(Store[V]) }
    def with_namespace(namespace); end

    sig { abstract.returns(String) }
    def store_type; end

    sig { overridable.params(other: T.self_type).void }
    def initialize_copy(other); end

    sig(:final) { params(key: T.any(String, CacheKey)).returns(CacheKey) }
    def namespaced_key(key); end

    sig { overridable.returns(Instrumenter) }
    def instrumenter; end
  end
end
