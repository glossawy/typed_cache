# typed: strict

module TypedCache
  module Instrumenters
    class << self
      sig { params(name: Symbol, klass: T::Class[::TypedCache::Instrumenter]).returns(T.self_type) }
      def register(name, klass); end

      sig { params(name: Symbol, args: T::Array[T.anything], options: T::Hash[Symbol, T.anything]).returns(T.self_type) }
      def resolve(name, *args, **options); end

      sig { returns(T::Array[T::Class[::TypedCache::Instrumenter]]) }
      def available; end

      sig { params(name: Symbol).returns(T::Boolean) }
      def registered?(name); end
    end
  end
end
