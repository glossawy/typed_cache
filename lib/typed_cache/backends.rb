# frozen_string_literal: true

require 'typed_cache/registry'

module TypedCache
  module Backends
    autoload :Memory, 'typed_cache/backends/memory'
    autoload :ActiveSupport, 'typed_cache/backends/active_support'

    # Backend registry using composition
    REGISTRY = Registry.new('backend', {
      memory: Memory,
    }).freeze

    private_constant :REGISTRY

    class << self
      extend Forwardable
      delegate [:resolve, :register, :available, :registered?] => :registry

      #: -> Registry
      def registry = REGISTRY

      # Convenience method delegating to registry
      # @rbs!
      #   def resolve: (Symbol, *untyped, **untyped) -> either[Error, Store[untyped]]
      #   def available: -> Array[Symbol]
      #   def register: (Symbol, Class) -> either[Error, void]
      #   def registered?: (Symbol) -> bool
    end
  end
end
