# typed: strict

module TypedCache
  module Backends
    module ActiveSupport
      extend T::Generic

      include ::TypedCache::Backend

      BackendType = type_member
    end
  end
end
