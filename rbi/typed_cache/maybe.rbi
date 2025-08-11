# typed: strict

module TypedCache
  module Maybe
    include Kernel
    extend T::Generic

    mixes_in_class_methods(T::Generic)

    sealed!
    interface!

    V = type_member(:out)

    sig { abstract.returns(T::Boolean) }
    def some?; end

    sig { abstract.returns(T::Boolean) }
    def nothing?; end

    sig { abstract.type_parameters(:T).params(block: T.proc.params(value: V).returns(T.type_parameter(:T))).returns(::TypedCache::Maybe[T.type_parameter(:T)]) }
    def map(&block); end

    sig { abstract.type_parameters(:T).params(block: T.proc.params(value: V).returns(::TypedCache::Maybe[T.type_parameter(:T)])).returns(::TypedCache::Maybe[T.type_parameter(:T)]) }
    def bind(&block); end

    alias flat_map bind

    class << self
      sig { type_parameters(:T).params(value: T.type_parameter(:T)).returns(::TypedCache::Some[T.type_parameter(:T)]) }
      def some(value); end

      sig { returns(::TypedCache::Nothing) }
      def none; end

      sig { params(value: NilClass).returns(::TypedCache::Nothing) }
      sig { params(value: ::TypedCache::Nothing).returns(::TypedCache::Nothing) }
      sig { type_parameters(:T).params(value: ::TypedCache::Some[T.type_parameter(:T)]).returns(::TypedCache::Some[T.type_parameter(:T)]) }
      sig { type_parameters(:T).params(value: T.type_parameter(:T)).returns(::TypedCache::Some[T.type_parameter(:T)]) }
      def wrap(value); end

      alias [] some
    end
  end

  class Some
    sealed!

    include ::TypedCache::Maybe
    extend T::Generic

    V = type_member(:out)

    sig { override.returns(TrueClass) }
    def some?; end

    sig { override.returns(FalseClass) }
    def nothing?; end

    sig { override.type_parameters(:T).params(block: T.proc.params(value: V).returns(T.type_parameter(:T))).returns(Some[T.type_parameter(:T)]) }
    def map(&block); end

    sig { override.type_parameters(:T).params(block: T.proc.params(value: V).returns(::TypedCache::Maybe[T.type_parameter(:T)])).returns(::TypedCache::Maybe[T.type_parameter(:T)]) }
    def bind(&block); end
  end

  class Nothing
    sealed!

    include ::TypedCache::Maybe
    extend T::Generic

    V = type_member(:out) { { fixed: T.noreturn } }

    sig { override.returns(FalseClass) }
    def some?; end

    sig { override.returns(TrueClass) }
    def nothing?; end

    sig { override.type_parameters(:T).params(block: T.proc.params(value: V).returns(T.type_parameter(:T))).returns(T.self_type) }
    def map(&block); end

    sig { override.type_parameters(:T).params(block: T.proc.params(value: V).returns(::TypedCache::Maybe[T.type_parameter(:T)])).returns(T.self_type) }
    def bind(&block); end
  end
end
