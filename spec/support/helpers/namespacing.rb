# frozen_string_literal: true

using(Module.new do
  refine Symbol do
    def as_infix_operator(*, **, &)
      proc { |lhs, rhs| lhs.public_send(self, rhs, *, **, &) }
    end
  end
end)

module Namespacing
  extend self

  class SimpleStore
    include TypedCache::Store

    def initialize(namespace, *, **, &)
      @namespace = namespace
      @backing_store = {}
    end

    def get(key)
      key = namespaced_key(key)
      if @backing_store.key?(key)
        TypedCache::Either.right(TypedCache::Snapshot.new(key, @backing_store[key], source: :cache))
      else
        TypedCache::Either.left(TypedCache::CacheMissError.new(key))
      end
    end

    def ref(key)
      TypedCache::CacheRef.new(self, namespaced_key(key))
    end

    def set(key, value)
      TypedCache::Either.right(TypedCache::Snapshot.new(namespaced_key(key), @backing_store[namespaced_key(key)] = value, source: :update))
    end

    def delete(key)
      key = namespaced_key(key)
      if @backing_store.key?(key)
        TypedCache::Either.right(TypedCache::Snapshot.new(key, @backing_store.delete(key), source: :cache))
      else
        TypedCache::Either.left(TypedCache::CacheMissError.new(key))
      end
    end

    def clear
      @backing_store.clear
      TypedCache::Maybe.none
    end

    def with_namespace(new_namespace)
      self.class.new(new_namespace, @backing_store)
    end

    attr_reader :namespace

    def store_type
      'simple'
    end

    def size
      @backing_store.size
    end
  end

  def create_store(namespace, *, **, &)
    SimpleStore.new(namespace)
  end

  def namespace(name, *nested_names)
    namespace = TypedCache::Namespace.at(name)

    nested_names.reduce(namespace, &:nested.as_infix_operator)
  end

  alias make_namespace namespace

  def cache_key(namespace, key)
    namespace = namespace(namespace) unless namespace.is_a?(TypedCache::Namespace)

    namespace.key(key)
  end
end
