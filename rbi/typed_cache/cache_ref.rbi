# typed: strict

module TypedCache
  class CacheRef
    extend T::Generic

    sealed!

    RefType = type_member

    sig { returns(::TypedCache::Either[Error, ::TypedCache::Snapshot[RefType]]) }
    def read; end

    sig { params(value: RefType).returns(::TypedCache::Either[Error, ::TypedCache::Snapshot[RefType]]) }
    def write(value); end

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

    sig { params(block: T.proc.params(value: RefType).returns(RefType)).returns(::TypedCache::Either[Error, ::TypedCache::Snapshot[RefType]]) }
    def compute_if_absent(&block); end

    sig { type_parameters(:T).params(block: T.proc.params(value: ::TypedCache::Snapshot[RefType]).returns(T.type_parameter(:T))).returns(::TypedCache::Either[Error, T.type_parameter(:T)]) }
    def with_snapshot(&block); end

    sig { type_parameters(:T).params(block: T.proc.params(value: RefType).returns(T.type_parameter(:T))).returns(::TypedCache::Either[Error, T.type_parameter(:T)]) }
    def with(&block); end

    sig { returns(String) }
    def to_s; end

    sig { returns(String) }
    def inspect; end
  end
end
