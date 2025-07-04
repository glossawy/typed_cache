# frozen_string_literal: true

require 'dry/struct'
require 'dry/types'

require_relative 'backends/memory'
require_relative 'backends/active_support'

module TypedCache
  module Backends
    # Backend registry using composition
    REGISTRY = Registry.new('backend', {
      memory: Memory,
      active_support: ActiveSupport,
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
