# typed: strict

module TypedCache
  module Decorator
    extend T::Generic

    include ::TypedCache::Backend

    abstract!

    BackendType = type_member
    KeyValue = T.type_alias { TypedCache::Backend::KeyValue }

    sig { params(backend: ::TypedCache::Backend[BackendType]).void }
    def initialize(backend); end

    sig { abstract.returns(::TypedCache::Backend[BackendType]) }
    def backend; end

    sig { override.params(key: KeyValue, opts: T::Hash[Symbol, T.untyped]).returns(::TypedCache::Either[Error, ::TypedCache::Snapshot[Maybe[BackendType]]]) }
    def read(key, **opts); end

    sig { override.params(key: KeyValue, value: BackendType, opts: T::Hash[Symbol, T.untyped]).returns(::TypedCache::Either[Error, ::TypedCache::Snapshot[BackendType]]) }
    def write(key, value, **opts); end

    sig { override.params(key: KeyValue).returns(::TypedCache::Either[Error, ::TypedCache::Snapshot[Maybe[BackendType]]]) }
    def delete(key); end

    sig { override.params(key: KeyValue).returns(T::Boolean) }
    def key?(key); end

    sig { override.params(key: KeyValue, opts: T::Hash[Symbol, T.untyped], block: T.proc.returns(T.nilable(BackendType))).returns(::TypedCache::Either[Error, ::TypedCache::Snapshot[Maybe[BackendType]]]) }
    def fetch(key, **opts, &block); end

    sig { override.params(keys: T::Array[KeyValue], opts: T::Hash[Symbol, T.untyped]).returns(::TypedCache::Either[Error, T::Hash[KeyValue, Snapshot[BackendType]]]) }
    def read_multi(keys, **opts); end

    sig { override.params(keys: T::Array[KeyValue], opts: T::Hash[Symbol, T.untyped], block: T.proc.params(key: KeyValue).returns(T.nilable(BackendType))).returns(::TypedCache::Either[Error, T::Hash[KeyValue, Snapshot[BackendType]]]) }
    def fetch_multi(keys, **opts, &block); end

    sig { override.params(values: T::Hash[KeyValue, BackendType], opts: T::Hash[Symbol, T.untyped]).returns(::TypedCache::Either[Error, T::Hash[KeyValue, Snapshot[BackendType]]]) }
    def write_multi(values, **opts); end

    sig { override.void }
    def clear; end

    sig { overridable.params(other: T.self_type).void }
    def initialize_copy(other); end

    sig { override.returns(T.nilable(::TypedCache::Instrumenter)) }
    def instrumenter; end
  end
end
