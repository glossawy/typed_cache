# typed: strict

module TypedCache
  class Snapshot
    extend T::Generic

    sealed!

    ValueType = type_member(:out)

    sig { returns(::TypedCache::CacheKey) }
    def key; end

    sig { returns(ValueType) }
    def value; end

    sig { returns(Time) }
    def retrieved_at; end

    sig { returns(Symbol) }
    def source; end

    sig { returns(Float) }
    def age; end

    sig { returns(T::Boolean) }
    def from_cache?; end

    sig { returns(T::Boolean) }
    def computed?; end

    sig { returns(T::Boolean) }
    def updated?; end

    sig { type_parameters(:T).params(block: T.proc.params(value: ValueType).returns(T.type_parameter(:T))).returns(::TypedCache::Snapshot[T.type_parameter(:T)]) }
    def map(&block); end

    sig { type_parameters(:T).params(block: T.proc.params(value: ValueType).returns(::TypedCache::Either[Error, T.type_parameter(:T)])).returns(::TypedCache::Either[Error, ::TypedCache::Snapshot[T.type_parameter(:T)]]) }
    def bind(&block); end

    alias flat_map bind

    class << self
      sig { type_parameters(:T).params(key: ::TypedCache::CacheKey, value: T.type_parameter(:T)).returns(::TypedCache::Snapshot[T.type_parameter(:T)]) }
      def cached(key, value); end

      sig { type_parameters(:T).params(key: ::TypedCache::CacheKey, value: T.type_parameter(:T)).returns(::TypedCache::Snapshot[T.type_parameter(:T)]) }
      def computed(key, value); end

      sig { type_parameters(:T).params(key: ::TypedCache::CacheKey, value: T.type_parameter(:T)).returns(::TypedCache::Snapshot[T.type_parameter(:T)]) }
      def updated(key, value); end
    end
  end
end
