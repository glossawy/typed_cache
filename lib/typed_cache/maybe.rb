# frozen_string_literal: true

module TypedCache
  # @rbs!
  #   type maybe[T] = (Nothing | Some[T]) & _Maybe[T]

  module Maybe
    include Kernel

    class << self
      #: [V](V) -> maybe[V]
      def some(value) = Some.new(value)
      #: -> maybe[bot]
      def none = Nothing.new

      #: [V](V? | maybe[V]) -> maybe[V]
      def wrap(value)
        case value
        when Nothing, Some then value
        when NilClass then Nothing.new
        else
          Some.new(value)
        end
      end

      alias [] some
    end
  end

  # @rbs!
  #   interface _Maybe[out V]
  #     def some?: -> bool
  #     def nothing?: -> bool
  #     def map: [T] () { (V) -> T } -> maybe[T]
  #     def bind: [T] () { (V) -> maybe[T] } -> maybe[T]
  #     def value_or: [T] (T) -> T
  #     def value_or_raise!: -> V
  #     alias flat_map bind
  #   end

  # @rbs generic out V
  class Some
    # @rbs! include _Maybe[V]

    attr_reader :value #: V

    #: (V) -> void
    def initialize(value)
      @value = value
    end

    # @rbs override
    #: -> TrueClass
    def some? = true
    # @rbs override
    #: -> FalseClass
    def nothing? = false

    # @rbs override
    #: [T] () { (V) -> T } -> maybe[T]
    def map(&) = Some.new(yield(value))

    # @rbs override
    #: [T] () { (V) -> maybe[T] } -> maybe[T]
    def bind(&) = yield(value)

    # @rbs override
    #: [T] (T) -> T
    def value_or(default) = value

    # @rbs override
    #: -> V
    def value_or_raise! = value

    alias flat_map bind

    #: (Array[top]) -> ({ value: V })
    def deconstruct_keys(keys)
      { value: }
    end

    # @rbs (other: Object) -> bool
    def ==(other)
      other.is_a?(Some) && other.value == value
    end

    # @rbs () -> Integer
    def hash = [Some, value].hash

    # @rbs () -> String
    def to_s = "Some(#{value})"

    # @rbs () -> String
    def inspect = "Some(#{value.inspect})"
  end

  class Nothing
    # @rbs! include _Maybe[bot]

    # @rbs override
    #: -> FalseClass
    def some? = false
    # @rbs override
    #: -> TrueClass
    def nothing? = true

    # @rbs override
    #: [T] () { (V) -> T } -> maybe[T]
    def map(&) = self

    # @rbs override
    #: [T] () { (V) -> maybe[T] } -> maybe[T]
    def bind(&) = self
    alias flat_map bind

    # @rbs override
    #: [T] (T) -> T
    def value_or(default) = default

    # @rbs override
    #: -> V
    def value_or_raise! = raise TypedCache::TypeError, 'Nothing has no value'

    # @rbs (other: Object) -> bool
    def ==(other)
      other.is_a?(Nothing)
    end

    # @rbs () -> Integer
    def hash = [Nothing].hash

    # @rbs () -> String
    def to_s = 'Nothing'

    # @rbs () -> String
    def inspect = to_s
  end
end
