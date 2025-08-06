# typed: strict

module TypedCache
  class CacheRef
    extend T::Generic

    sealed!

    V = type_member

    sig { returns(::TypedCache::Either[Error, ::TypedCache::Snapshot[V]]) }
    def get; end

    sig { params(value: V).returns(::TypedCache::Either[Error, ::TypedCache::Snapshot[V]]) }
    def set(value); end

    sig { returns(::TypedCache::Either[Error, ::TypedCache::Snapshot[V]]) }
    def delete; end

    sig { params(block: T.proc.params(value: V).returns(V)).returns(::TypedCache::Either[Error, ::TypedCache::Snapshot[V]]) }
    def fetch(&block); end

    sig { returns(T::Boolean) }
    def present?; end

    sig { returns(T::Boolean) }
    def empty?; end

    sig { params(block: T.proc.params(value: V).returns(V)).returns(::TypedCache::Either[Error, ::TypedCache::Snapshot[V]]) }
    def update(&block); end

    sig { params(default: V).returns(V) }
    def value_or(default); end

    sig { returns(::TypedCache::Maybe[V]) }
    def value_maybe; end

    sig { params(block: T.proc.params(value: V).returns(V)).returns(::TypedCache::Either[Error, ::TypedCache::Snapshot[V]]) }
    def compute_if_absent(&block); end

    sig { params(new_key: String).returns(::TypedCache::CacheRef[V]) }
    def with_key(new_key); end

    sig { params(scope_key: String).returns(::TypedCache::CacheRef[V]) }
    def scope(scope_key); end

    sig { type_parameters(:T).params(left_fn: T.proc.params(value: Error).returns(T.type_parameter(:T)), right_fn: T.proc.params(value: ::TypedCache::Snapshot[V]).returns(T.type_parameter(:T))).returns(T.type_parameter(:T)) }
    def fold(left_fn, right_fn); end

    sig { type_parameters(:T).params(block: T.proc.params(value: ::TypedCache::Snapshot[V]).returns(T.type_parameter(:T))).returns(::TypedCache::Either[Error, T.type_parameter(:T)]) }
    def with_snapshot(&block); end

    sig { type_parameters(:T).params(block: T.proc.params(value: V).returns(T.type_parameter(:T))).returns(::TypedCache::Either[Error, T.type_parameter(:T)]) }
    def with(&block); end
  end
end
