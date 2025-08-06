# frozen_string_literal: true

require 'dry/struct'
require 'dry/types'

module TypedCache
  module Clock
    # @rbs generic R
    class Measured < Dry::Struct
      # @rbs! def start: () -> Float
      # @rbs! def end: () -> Float
      # @rbs! def result: () -> [R]

      attribute :start, Dry.Types::Float
      attribute :end, Dry.Types::Float
      attribute :result, Dry.Types.Instance(Object) #: [R]

      # @rbs! def initialize: (start: Float, end: Float, result: [R]) -> void

      #: -> Float
      def duration
        self.end - start
      end
    end

    class << self
      # @rbs [R]() { () -> R } -> Measured[R]
      def measure(&)
        start = now
        result = yield
        Measured.new(start:, end: now, result:)
      end

      # @rbs () -> Time
      def now
        Time.now
      end
    end
  end
end
