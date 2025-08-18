# typed: strict

module TypedCache
  class CacheKey
    sealed!

    sig { returns(::TypedCache::Namespace) }
    attr_reader :namespace

    sig { returns(String) }
    attr_reader :key

    sig { returns(String) }
    def to_s; end

    sig { returns(String) }
    def inspect; end

    sig { returns(Integer) }
    def hash; end

    sig { params(other: Object).returns(T::Boolean) }
    def ==(other); end

    private

    sig { returns(String) }
    def delimiter; end
  end
end
