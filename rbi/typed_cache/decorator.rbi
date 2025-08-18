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

    sig { override.overridable.params(key: KeyValue, opts: T::Hash[Symbol, T.untyped]).returns(T.nilable(BackendType)) }
    def read(key, **opts); end

    sig { override.overridable.params(key: KeyValue, value: BackendType, opts: T::Hash[Symbol, T.untyped]).returns(BackendType) }
    def write(key, value, **opts); end

    sig { override.overridable.params(key: KeyValue, opts: T::Hash[Symbol, T.untyped]).returns(T.nilable(BackendType)) }
    def delete(key, **opts); end

    sig { override.overridable.params(key: KeyValue).returns(T::Boolean) }
    def key?(key); end

    sig { override.overridable.params(key: KeyValue, opts: T::Hash[Symbol, T.untyped], block: T.proc.returns(T.nilable(BackendType))).returns(T.nilable(BackendType)) }
    def fetch(key, **opts, &block); end

    sig { override.overridable.params(keys: T::Array[KeyValue], opts: T::Hash[Symbol, T.untyped]).returns(T::Hash[KeyValue, BackendType]) }
    def read_multi(keys, **opts); end

    sig { override.overridable.params(keys: T::Array[KeyValue], opts: T::Hash[Symbol, T.untyped], block: T.proc.params(key: KeyValue).returns(T.nilable(BackendType))).returns(T::Hash[KeyValue, BackendType]) }
    def fetch_multi(keys, **opts, &block); end

    sig { override.overridable.params(values: T::Hash[KeyValue, BackendType], opts: T::Hash[Symbol, T.untyped]).returns(T::Hash[KeyValue, BackendType]) }
    def write_multi(values, **opts); end

    sig { override.overridable.void }
    def clear; end

    sig { overridable.params(other: T.self_type).void }
    def initialize_copy(other); end
  end
end
