# typed: strict

module TypedCache
  module Instrumenters
    module Mixins
      module NamedspacedSingleton
        requires_ancestor { Instrumenter }

        class << self
          sig { returns(T::Array[T::Class[T.all(Instrumenter, NamedspacedSingleton)]]) }
          def all; end
        end

        sig { params(namespace: Namespace).void }
        def initialize(namespace); end

        sig { returns(Namespace) }
        def namespace; end

        module ClassMethods
          sig { params(namespace: Namespace).returns(T::Class[T.all(Instrumenter, NamedspacedSingleton)]) }
          def new(namespace: T.unsafe(nil)); end

          sig { params(namespace: Namespace).returns(T::Class[T.all(Instrumenter, NamedspacedSingleton)]) }
          def get(namespace); end

          sig { void }
          def clear_namespace_cache; end
        end
      end
    end
  end
end
