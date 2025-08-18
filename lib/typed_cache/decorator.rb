# frozen_string_literal: true

require 'forwardable'

module TypedCache
  # Marker mixin for cache store decorators. A decorator behaves exactly like a
  # Store but must accept another Store instance in its constructor.
  # @rbs generic V
  module Decorator
    extend Forwardable

    # @rbs!
    #   interface _Decorator[V]
    #     def initialize: (Backend[V]) -> void
    #   end

    include Backend #[V]
    # @rbs! include Backend::_Backend[V]
    # @rbs! include _Decorator[V]

    # @rbs override
    # @rbs () -> Backend[V]
    def backend = raise NotImplementedError, "#{self.class} must implement #backend"

    Backend.instance_methods(false).each do |method_name|
      def_delegator :backend, method_name
    end

    # @rbs override
    #: (self) -> void
    def initialize_copy(other)
      super

      @backend = other.backend.clone
    end

    # @rbs override
    # @rbs () -> String
    def to_s = "#{self.class.name}(#{backend})"

    # @rbs override
    # @rbs () -> String
    def inspect = "Decorator(#{self.class.name}, #{backend.inspect})"
  end

  # @rbs! type decorator[V] = Decorator::_Decorator[V] & Backend[V]
end
