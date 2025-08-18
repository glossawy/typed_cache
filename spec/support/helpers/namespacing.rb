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

  def create_store(namespace, *, **, &)
    TypedCache::Store.new(namespace, TypedCache::Backends::Memory.new)
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
