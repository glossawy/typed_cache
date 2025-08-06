# typed: strict

module TypedCache
  class CacheKey
    sealed!

    sig { returns(Namespace) }
    attr_reader :namespace

    sig { returns(String) }
    attr_reader :key

    sig { returns(String) }
    def to_s; end
  end
end
