# typed: strict

module TypedCache
  module Backend
    extend T::Generic

    interface!

    BackendType = type_member

    KeyValue = T.type_alias { T.any(CacheKey, String) }

    sig { abstract.params(key: KeyValue, opts: T::Hash[Symbol, T.untyped]).returns(Either[Error, Snapshot[Maybe[BackendType]]]) }
    def read(key, **opts); end

    sig { abstract.params(key: KeyValue, value: BackendType, opts: T::Hash[Symbol, T.untyped]).returns(Either[Error, Snapshot[BackendType]]) }
    def write(key, value, **opts); end

    sig { abstract.params(key: KeyValue).returns(Either[Error, Snapshot[Maybe[BackendType]]]) }
    def delete(key); end

    sig { abstract.params(keys: T::Array[KeyValue], opts: T::Hash[Symbol, T.untyped]).returns(Either[Error, T::Hash[KeyValue, Snapshot[BackendType]]]) }
    def read_multi(keys, **opts); end

    sig { abstract.params(values: T::Hash[KeyValue, BackendType], opts: T::Hash[Symbol, T.untyped]).returns(Either[Error, T::Hash[KeyValue, Snapshot[BackendType]]]) }
    def write_multi(values, **opts); end

    sig { abstract.void }
    def clear; end

    sig { abstract.params(key: KeyValue).returns(T::Boolean) }
    def key?(key); end

    sig { abstract.returns(T.nilable(Instrumenter)) }
    def instrumenter; end

    sig do
      abstract
        .type_parameters(:K)
        .params(key: T.all(KeyValue, T.type_parameter(:K)), block: T.proc.params(key: T.all(KeyValue, T.type_parameter(:K))).returns(T.nilable(BackendType))).returns(Either[Error, Snapshot[Maybe[BackendType]]])
    end
    def fetch(key, &block); end

    sig do
      abstract
        .type_parameters(:K)
        .params(keys: T::Array[T.all(KeyValue, T.type_parameter(:K))], block: T.proc.params(key: T.all(KeyValue, T.type_parameter(:K))).returns(T.nilable(BackendType))).returns(Either[Error, T::Hash[KeyValue, Snapshot[BackendType]]])
    end
    def fetch_multi(keys, &block); end
  end
end
