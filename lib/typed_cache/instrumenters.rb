# frozen_string_literal: true

require 'typed_cache/instrumenters/mixins'
require 'typed_cache/instrumenters/mixins/namespaced_singleton'

module TypedCache
  module Instrumenters
    autoload :ActiveSupport, 'typed_cache/instrumenters/active_support'
    autoload :Monitor, 'typed_cache/instrumenters/monitor'
    autoload :Null, 'typed_cache/instrumenters/null'

    # @api private
    # Registry mapping symbols to instrumenter classes. We can't reuse the generic
    # Registry class directly because many instrumenters mix in `Singleton`,
    # making `.new` inaccessible. Instead we implement a thin facade that
    # returns either the singleton instance (preferred) or a fresh instance.
    REGISTRY = Registry.new('instrumenter', {
      dry: Monitor,
      rails: ActiveSupport,
      default: Null,
      null: Null,
    }) #: Registry[Symbol, Class[Instrumenter]]

    class << self
      extend Forwardable

      # @api private
      # @rbs () -> Registry[Symbol, Class[Instrumenter]]
      def registry = REGISTRY

      # @rbs! def register: (Symbol, Class[Instrumenter]) -> void
      # @rbs! def resolve: (Symbol, **untyped) -> either[Error, Instrumenter]
      # @rbs! def available: () -> Array[Symbol]
      # @rbs! def registered?: (Symbol) -> Boolean

      def_delegators :registry, :resolve, :available, :registered?, :register
    end
  end
end
