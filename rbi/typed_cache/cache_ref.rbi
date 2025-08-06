# typed: strict

module TypedCache
  class CacheRef
    extend T::Generic

    sealed!

    RefType = type_member

    sig { returns(::TypedCache::Either[Error, ::TypedCache::Snapshot[RefType]]) }
    def get; end

    sig { params(value: RefType).returns(::TypedCache::Either[Error, ::TypedCache::Snapshot[RefType]]) }
    def set(value); end

    sig { returns(::TypedCache::Either[Error, ::TypedCache::Snapshot[RefType]]) }
    def delete; end

    sig { params(block: T.proc.params(value: RefType).returns(RefType)).returns(::TypedCache::Either[Error, ::TypedCache::Snapshot[RefType]]) }
    def fetch(&block); end

    sig { returns(T::Boolean) }
    def present?; end

    sig { returns(T::Boolean) }
    def empty?; end

    sig { params(block: T.proc.params(value: RefType).returns(RefType)).returns(::TypedCache::Either[Error, ::TypedCache::Snapshot[RefType]]) }
    def update(&block); end

    sig { params(default: RefType).returns(RefType) }
    def value_or(default); end

    sig { returns(::TypedCache::Maybe[RefType]) }
    def value_maybe; end

    sig { params(block: T.proc.params(value: RefType).returns(RefType)).returns(::TypedCache::Either[Error, ::TypedCache::Snapshot[RefType]]) }
    def compute_if_absent(&block); end

    sig { params(new_key: String).returns(::TypedCache::CacheRef[RefType]) }
    def with_key(new_key); end

    sig { params(scope_key: String).returns(::TypedCache::CacheRef[RefType]) }
    def scope(scope_key); end

    sig { type_parameters(:T).params(left_fn: T.proc.params(value: Error).returns(T.type_parameter(:T)), right_fn: T.proc.params(value: ::TypedCache::Snapshot[RefType]).returns(T.type_parameter(:T))).returns(T.type_parameter(:T)) }
    def fold(left_fn, right_fn); end

    sig { type_parameters(:T).params(block: T.proc.params(value: ::TypedCache::Snapshot[RefType]).returns(T.type_parameter(:T))).returns(::TypedCache::Either[Error, T.type_parameter(:T)]) }
    def with_snapshot(&block); end

    sig { type_parameters(:T).params(block: T.proc.params(value: RefType).returns(T.type_parameter(:T))).returns(::TypedCache::Either[Error, T.type_parameter(:T)]) }
    def with(&block); end
  end
end
