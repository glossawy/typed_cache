# frozen_string_literal: true

require 'typed_cache/registry'

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
    autoload :Instrumented, 'typed_cache/decorators/instrumented'

    # @api private
    # Default decorator set – starts with instrumentation only, but this registry
    # lets end-users register their own via `Decorators.register`.
    REGISTRY = Registry.new('decorator', {
      instrumented: Instrumented,
    }).freeze

    class << self
      extend Forwardable

      # Delegate common registry helpers
      delegate [:resolve, :register, :available, :registered?] => :registry

      # @api private
      # @rbs () -> Registry[Store[untyped]]
      def registry = REGISTRY
    end
  end
end
