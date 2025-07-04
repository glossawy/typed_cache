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

    alias flat_map bind

    #: (Array[top]) -> ({ value: V })
    def deconstruct_keys(keys)
      { value: }
    end
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
  end
end
