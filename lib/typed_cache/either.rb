# frozen_string_literal: true

module TypedCache
  # @rbs! type either[out E, out R] = (Left[E] | Right[R]) & _Either[E, R]

  module Either
    include Kernel

    class << self
      #: [E] (E) -> either[E, bot]
      def left(error) = Left.new(error)
      #: [R] (R) -> either[bot, R]
      def right(value) = Right.new(value)

      #: [E, R] (E | R) -> either[E, R]
      def wrap(value, error_class = StandardError)
        case value
        when Left, Right then value
        when error_class then Left.new(value)
        else
          Right.new(value)
        end
      end
    end
  end

  # @rbs! interface _Either[out E, out R]
  #     def left?: -> bool
  #     def right?: -> bool
  #     def right_or_else: (^(E) -> void) -> R
  #     def right_or_raise!: -> R
  #     def map: [T] () { (R) -> T } -> either[E, T]
  #     def bind: [E2, R2] () { (R) -> either[E2, R2] } -> either[E | E2, R2]
  #     def map_left: [F] () { (E) -> F } -> either[F, R]
  #     def fold: [T, E, R] (^(E) -> T, ^(R) -> T) -> T
  #   end

  # @rbs generic out E
  class Left
    # @rbs! include _Either[E, bot]

    attr_reader :error #: E

    alias value error

    #: (E) -> void
    def initialize(error)
      @error = error
    end

    # @rbs override
    #: -> true
    def left? = true

    # @rbs override
    #: -> false
    def right? = false

    # @rbs override
    #: (^(E) -> void) -> bot
    def right_or_else(&) = yield(error)

    # @rbs override
    #: -> bot
    def right_or_raise! = raise(error)

    # @rbs override
    #: [T] () { (R) -> T } -> either[E, T]
    def map(&) = self

    # @rbs override
    #: [E2, R2] () { (R) -> either[E2, R2] } -> either[E | E2, R2]
    def bind(&) = self

    # @rbs override
    #: [F] () { (E) -> F } -> either[F, R]
    def map_left(&) = Left.new(yield(error))

    # @rbs override
    #: [T, E, R] (^(E) -> T, ^(R) -> T) -> T
    def fold(left_fn, right_fn)
      left_fn.call(error)
    end

    #: (Array[top]) -> ({ error: E })
    def deconstruct_keys(keys)
      { error: }
    end

    # @rbs (other: Object) -> bool
    def ==(other)
      other.is_a?(Left) && other.error == error
    end

    # @rbs () -> Integer
    def hash = [Left, error].hash

    # @rbs () -> String
    def to_s = "Left(#{error})"

    # @rbs () -> String
    def inspect = "Left(#{error.inspect})"
  end

  # @rbs generic out R
  class Right
    # @rbs! include _Either[bot, R]

    attr_reader :value #: R

    alias result value

    #: (R) -> void
    def initialize(value)
      @value = value
    end

    # @rbs override
    #: -> false
    def left? = false

    # @rbs override
    #: -> true
    def right? = true

    # @rbs override
    #: (^(E) -> void) -> R
    def right_or_else(&) = value

    # @rbs override
    #: -> R
    def right_or_raise! = value

    # @rbs override
    #: [T] () { (R) -> T } -> either[E, T]
    def map(&) = Right.new(yield(value))

    # @rbs override
    #: [E2, R2] () { (R) -> either[E2, R2] } -> either[E | E2, R2]
    def bind(&) = yield(value)

    # @rbs override
    #: [F] () { (E) -> F } -> either[F, R]
    def map_left(&) = self

    # @rbs override
    #: [T, E, R] (^(E) -> T, ^(R) -> T) -> T
    def fold(left_fn, right_fn)
      right_fn.call(value)
    end

    #: (Array[top]) -> ({ value: R })
    def deconstruct_keys(keys)
      { value: }
    end

    # @rbs (other: Object) -> bool
    def ==(other)
      other.is_a?(Right) && other.value == value
    end

    # @rbs () -> Integer
    def hash = [Right, value].hash

    # @rbs () -> String
    def to_s = "Right(#{value})"

    # @rbs () -> String
    def inspect = "Right(#{value.inspect})"
  end
end
