# typed: strict

module TypedCache
  module Backend
    include Store
    V = type_member
  end
end
