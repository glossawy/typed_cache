# typed: strict

module TypedCache
  module Either
    include Kernel

    sealed!
    interface!

    module Private
      module Interface
        L = type_member(:out)
        R = type_member(:out)

        interface!

        sig { abstract.returns(T::Boolean) }
        def left?; end

        sig { abstract.returns(T::Boolean) }
        def right?; end

        sig { abstract.type_parameters(:T).params(block: T.proc.params(value: R).returns(T.type_parameter(:T))).returns(Interface[L, T.type_parameter(:T)]) }
        def map(&block); end

        sig { abstract.type_parameters(:T).params(block: T.proc.params(value: L).returns(T.type_parameter(:T))).returns(Interface[T.type_parameter(:T), R]) }
        def map_left(&block); end

        sig { abstract.type_parameters(:E, :R2).params(block: T.proc.params(value: R).returns(Interface[T.type_parameter(:E), T.type_parameter(:R2)])).returns(Interface[T.type_parameter(:E), T.type_parameter(:R2)]) }
        def bind(&block); end

        sig { abstract.type_parameters(:T).params(left_block: T.proc.params(value: L).returns(T.type_parameter(:T)), right_block: T.proc.params(value: R).returns(T.type_parameter(:T))).returns(T.type_parameter(:T)) }
        def fold(left_block, right_block); end
      end
    end

    private_constant :Private

    include Private::Interface

    L = type_member(:out)
    R = type_member(:out)

    class Left
      sealed!

      include ::TypedCache::Either

      L = type_member(:out)
      R = type_member(:out) { { fixed: T.noreturn } }

      sig { override.returns(TrueClass) }
      def left?; end

      sig { override.returns(FalseClass) }
      def right?; end

      sig { override.type_parameters(:T).params(block: T.proc.params(value: R).returns(T.type_parameter(:T))).returns(T.self_type) }
      def map(&block); end

      sig { override.type_parameters(:T).params(block: T.proc.params(value: L).returns(T.type_parameter(:T))).returns(Left[T.type_parameter(:T)]) }
      def map_left(&block); end

      sig { override.type_parameters(:E, :R2).params(block: T.proc.params(value: R).returns(::TypedCache::Either[T.type_parameter(:E), T.type_parameter(:R2)])).returns(T.self_type) }
      def bind(&block); end

      sig { override.type_parameters(:T).params(left_block: T.proc.params(value: L).returns(T.type_parameter(:T)), right_block: T.proc.params(value: R).returns(T.type_parameter(:T))).returns(T.type_parameter(:T)) }
      def fold(left_block, right_block); end
    end

    class Right
      sealed!

      include ::TypedCache::Either

      L = type_member(:out) { { fixed: T.noreturn } }
      R = type_member(:out)

      sig { override.returns(FalseClass) }
      def left?; end

      sig { override.returns(TrueClass) }
      def right?; end

      sig { override.type_parameters(:T).params(block: T.proc.params(value: R).returns(T.type_parameter(:T))).returns(Right[T.type_parameter(:T)]) }
      def map(&block); end

      sig { override.type_parameters(:T).params(block: T.proc.params(value: L).returns(T.type_parameter(:T))).returns(T.self_type) }
      def map_left(&block); end

      sig { override.type_parameters(:E, :R2).params(block: T.proc.params(value: R).returns(::TypedCache::Either[T.type_parameter(:E), T.type_parameter(:R2)])).returns(::TypedCache::Either[T.type_parameter(:E), T.type_parameter(:R2)]) }
      def bind(&block); end

      sig { override.type_parameters(:T).params(left_block: T.proc.params(value: L).returns(T.type_parameter(:T)), right_block: T.proc.params(value: R).returns(T.type_parameter(:T))).returns(T.type_parameter(:T)) }
      def fold(left_block, right_block); end
    end
  end
end
