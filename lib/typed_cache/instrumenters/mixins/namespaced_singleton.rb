# frozen_string_literal: true

module TypedCache
  module Instrumenters
    module Mixins
      module NamespacedSingleton
        class << self
          # @rbs (Class[Instrumenter & NamespacedSingleton]) -> void
          def included(base)
            base.singleton_class.class_eval do
              alias private_new new
              private(:private_new)
            end

            base.extend(ClassMethods)
          end
        end

        NAMESPACE_CACHE = Concurrent::Map.new #: Concurrent::Map[String, Class[Instrumenter & NamespacedSingleton]]

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
            NAMESPACE_CACHE.compute_if_absent(namespace.to_s) { private_new(namespace) }
          end

          # @rbs (String) -> maybe[class]
          def get(namespace)
            NAMESPACE_CACHE.get(namespace.to_s)
          end
        end
      end
    end
  end
end
