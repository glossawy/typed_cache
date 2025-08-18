# typed: strict

module TypedCache
  module Backend
    extend T::Generic

    abstract!

    BackendType = type_member

    KeyValue = T.type_alias { T.any(::TypedCache::CacheKey, String) }

    sig { abstract.params(key: KeyValue, opts: T::Hash[Symbol, T.untyped]).returns(T.nilable(BackendType)) }
    def read(key, **opts); end

    sig { abstract.params(key: KeyValue, value: BackendType, opts: T::Hash[Symbol, T.untyped]).returns(BackendType) }
    def write(key, value, **opts); end

    sig { abstract.params(key: KeyValue, opts: T::Hash[Symbol, T.untyped]).returns(T.nilable(BackendType)) }
    def delete(key, **opts); end

    sig { abstract.params(keys: T::Array[KeyValue], opts: T::Hash[Symbol, T.untyped]).returns(T::Hash[KeyValue, BackendType]) }
    def read_multi(keys, **opts); end

    sig { abstract.params(values: T::Hash[KeyValue, BackendType], opts: T::Hash[Symbol, T.untyped]).returns(T::Hash[KeyValue, BackendType]) }
    def write_multi(values, **opts); end

    sig { abstract.void }
    def clear; end

    sig { abstract.params(key: KeyValue).returns(T::Boolean) }
    def key?(key); end

    sig do
      abstract
        .type_parameters(:K)
        .params(key: T.all(KeyValue, T.type_parameter(:K)), opts: T::Hash[Symbol, T.untyped], block: T.proc.params(key: T.all(KeyValue, T.type_parameter(:K))).returns(T.nilable(BackendType))).returns(T.nilable(BackendType))
    end
    def fetch(key, **opts, &block); end

    sig do
      abstract
        .type_parameters(:K)
        .params(keys: T::Array[T.all(KeyValue, T.type_parameter(:K))], opts: T::Hash[Symbol, T.untyped], block: T.proc.params(key: T.all(KeyValue, T.type_parameter(:K))).returns(T.nilable(BackendType))).returns(T::Hash[T.all(KeyValue, T.type_parameter(:K)), BackendType])
    end
    def fetch_multi(keys, **opts, &block); end
  end
end
