# typed: strict

module TypedCache
  class Error < StandardError; end

  class StoreError < ::TypedCache::Error
    sig { params(operation: Symbol, key: ::TypedCache::CacheKey, message: String, original_error: T.nilable(Error)).void }
    def initialize(operation, key, message, original_error = nil); end
  end

  class TypeError < ::TypedCache::Error
    sig { params(expected_type: String, actual_type: String, value: T.untyped, message: String).void }
    def initialize(expected_type, actual_type, value, message); end
  end

  class CacheMissError < ::TypedCache::Error
    sig { params(key: ::TypedCache::CacheKey).void }
    def initialize(key); end
  end
end
