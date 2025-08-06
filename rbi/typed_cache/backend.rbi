# typed: strict

module TypedCache
  module Backend
    extend T::Generic
    include ::TypedCache::Store
    V = type_member
  end
end
