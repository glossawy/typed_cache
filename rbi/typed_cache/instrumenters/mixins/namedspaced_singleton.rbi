# typed: strict

module TypedCache
  module Instrumenters
    module Mixins
      module NamedspacedSingleton
        requires_ancestor { ::TypedCache::Instrumenter }

        class << self
          sig { returns(T::Array[T::Class[T.all(::TypedCache::Instrumenter, ::TypedCache::Instrumenters::Mixins::NamedspacedSingleton)]]) }
          def all; end
        end

        sig { params(namespace: ::TypedCache::Namespace).void }
        def initialize(namespace); end

        sig { returns(::TypedCache::Namespace) }
        def namespace; end

        module ClassMethods
          sig { params(namespace: ::TypedCache::Namespace).returns(T::Class[T.all(::TypedCache::Instrumenter, ::TypedCache::Instrumenters::Mixins::NamedspacedSingleton)]) }
          def new(namespace: T.unsafe(nil)); end

          sig { params(namespace: ::TypedCache::Namespace).returns(T::Class[T.all(::TypedCache::Instrumenter, ::TypedCache::Instrumenters::Mixins::NamedspacedSingleton)]) }
          def get(namespace); end

          sig { void }
          def clear_namespace_cache; end
        end
      end
    end
  end
end
