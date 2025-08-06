# typed: strict

module TypedCache
  class Snapshot
    sealed!

    V = type_member

    sig { returns(V) }
    def value; end

    sig { returns(Time) }
    def retrieved_at; end

    sig { returns(Symbol) }
    def source; end

    sig { returns(Float) }
    def age; end

    sig { returns(T::Boolean) }
    def from_cache?; end

    sig { returns(T::Boolean) }
    def computed?; end

    sig { returns(T::Boolean) }
    def updated?; end

    sig { type_parameters(:T).params(block: T.proc.params(value: V).returns(T.type_parameter(:T))).returns(Snapshot[T.type_parameter(:T)]) }
    def map(&block); end

    sig { type_parameters(:T).params(block: T.proc.params(value: V).returns(Either[Error, T.type_parameter(:T)])).returns(Either[Error, Snapshot[T.type_parameter(:T)]]) }
    def bind(&block); end

    alias flat_map bind

    class << self
      sig { type_parameters(:T).params(value: T.type_parameter(:T)).returns(Snapshot[T.type_parameter(:T)]) }
      def computed(value); end

      sig { type_parameters(:T).params(value: T.type_parameter(:T)).returns(Snapshot[T.type_parameter(:T)]) }
      def updated(value); end
    end
  end
end
