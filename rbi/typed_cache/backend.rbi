# typed: strict

module TypedCache
  module Backend
    extend T::Generic
    include ::TypedCache::Store
    CachedType = type_member
  end
end
