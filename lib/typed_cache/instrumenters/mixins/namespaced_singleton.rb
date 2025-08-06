# frozen_string_literal: true

module TypedCache
  module Instrumenters
    module Mixins
      module NamespacedSingleton
        class << self
          # @rbs () -> Array[Class[Instrumenter & NamespacedSingleton]]
          def all = @all ||= [] # rubocop:disable ThreadSafety

          # @rbs (Class[Instrumenter & NamespacedSingleton]) -> void
          def included(base)
            base.singleton_class.class_eval do
              alias private_new new
              private(:private_new)
            end

            base.extend(ClassMethods)

            all << base
          end
        end

        # @rbs override
        # @rbs () -> String
        def namespace
          @namespace
        end

        # @rbs (String | Namespace) -> void
        def initialize(namespace)
          @namespace = namespace.to_s
        end

        module ClassMethods
          # @rbs (String | Namespace) -> class
          def new(namespace: TypedCache.config.instrumentation.namespace)
            namespace_cache.compute_if_absent(namespace.to_s) { private_new(namespace) }
          end

          # @rbs (String) -> maybe[class]
          def get(namespace)
            namespace_cache.get(namespace.to_s)
          end

          # @rbs () -> Concurrent::Map[String, Class[Instrumenter & NamespacedSingleton]]
          def namespace_cache = @namespace_cache ||= Concurrent::Map.new # rubocop:disable ThreadSafety
        end
      end
    end
  end
end
