# typed: strict

module TypedCache
  module Store
    abstract!

    V = type_member

    Key = T.type_alias { T.any(String, CacheKey) }
    private_constant :Key

    sig { params(key: Key).returns(Either[Error, V]) }
    def get(key); end

    sig { params(key: Key, value: V).returns(Either[Error, Snapshot[V]]) }
    def set(key, value); end

    sig { params(key: Key).returns(Either[Error, Snapshot[V]]) }
    def delete(key); end

    sig { params(key: Key).returns(CacheRef[V]) }
    def ref(key); end

    sig { void }
    def clear; end

    sig { params(key: Key).returns(T::Boolean) }
    def key?(key); end

    sig { params(key: Key, block: T.proc.params(value: V).returns(V)).returns(Either[Error, Snapshot[V]]) }
    def fetch(key, &block); end

    sig { returns(Namespace) }
    def namespace; end

    sig { params(namespace: Namespace).returns(Store[V]) }
    def with_namespace(namespace); end

    sig { returns(String) }
    def store_type; end

    sig { returns(T.self_type) }
    def clone; end

    sig { params(key: Key).returns(CacheKey) }
    def namespaced_key(key); end

    sig { returns(Instrumenter) }
    def instrumenter; end

    protected

    sig { params(string: String).returns(String) }
    def snake_case(string); end

    sig { params(namespace: Namespace).returns(Namespace) }
    def nested_namespace(namespace); end
  end
end
