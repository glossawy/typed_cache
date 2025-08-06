# typed: strict

module TypedCache
  module Backends
    module Memory
      extend T::Generic

      include ::TypedCache::Backend

      CachedType = type_member
    end
  end
end
