# typed: strict

module TypedCache
  module Decorators
    module Instrumented
      extend T::Generic

      include ::TypedCache::Decorator

      BackendType = type_member
    end
  end
end
