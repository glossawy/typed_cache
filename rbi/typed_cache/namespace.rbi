# typed: strict

module TypedCache
  class Namespace
    sealed!

    class << self
      sig { returns(T.attached_class) }
      def root; end

      sig { params(namespace: String, namespaces: String).returns(T.attached_class) }
      def at(namespace, *namespaces); end
    end

    sig { params(namespace: String, key_factory: T.nilable(T.proc.params(namespace: ::TypedCache::Namespace, key: String).returns(::TypedCache::CacheKey))).returns(::TypedCache::Namespace) }
    def nested(namespace, &key_factory); end

    sig { params(namespaces: String, key_factory: T.nilable(T.proc.params(namespace: ::TypedCache::Namespace, key: String).returns(::TypedCache::CacheKey))).returns(::TypedCache::Namespace) }
    def join(*namespaces, &key_factory); end

    sig { returns(::TypedCache::Namespace) }
    def parent_namespace; end

    sig { params(key: String).returns(::TypedCache::CacheKey) }
    def key(key); end

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
