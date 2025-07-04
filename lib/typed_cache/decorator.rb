# frozen_string_literal: true

module TypedCache
  # Marker mixin for cache store decorators. A decorator behaves exactly like a
  # Store but must accept another Store instance in its constructor.
  # @rbs generic V
  module Decorator
    include Store #[V]
    # @rbs! include Store::_Store[V]
    # @rbs! include Store::_Decorator[V]
  end
end
