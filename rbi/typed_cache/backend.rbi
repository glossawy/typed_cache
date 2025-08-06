# typed: strict

module TypedCache
  module Backend
    include ::TypedCache::Store
    V = type_member
  end
end
