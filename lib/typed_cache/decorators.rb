# frozen_string_literal: true

module TypedCache
  # Holds store decorators (e.g., instrumentation wrappers) that can be composed
  # by the CacheBuilder. Decorators must conform to the same API as the wrapped
  # store (see `TypedCache::Store`) and accept the store instance as their first
  # constructor argument.
  #
  # Example:
  #   Decorators.register(:my_decorator, MyDecorator)
  #   cache = TypedCache.builder
  #              .with_backend { |reg, ns| reg.resolve(:memory, ns).value }
  #              .with_decorator(:my_decorator)
  #              .build.value
  #
  module Decorators
    # Default decorator set – starts with instrumentation only, but this registry
    # lets end-users register their own via `Decorators.register`.
    REGISTRY = Registry.new('decorator', {
      instrumented: Store::Instrumented,
    }).freeze

    private_constant :REGISTRY

    class << self
      extend Forwardable

      # Delegate common registry helpers
      delegate [:resolve, :register, :available, :registered?] => :registry

      # @rbs () -> Registry[Store[untyped]]
      def registry = REGISTRY
    end
  end
end
