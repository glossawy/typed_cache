# frozen_string_literal: true

module TypedCache
  class CacheKey
    extend Forwardable

    attr_reader :namespace #: Namespace
    attr_reader :key       #: String

    # @rbs (Namespace, String) -> void
    def initialize(namespace, key)
      @namespace = namespace
      @key = key
    end

    # @rbs (Namespace) -> bool
    def belongs_to?(namespace)
      @namespace.to_s.start_with?(namespace.to_s)
    end

    # @rbs () -> String
    def to_s
      "#{@namespace}:#{@key}"
    end

    alias cache_key to_s

    # @rbs () -> String
    def inspect
      "#<#{self.class} namespace=#{@namespace} key=#{@key}>"
    end

    # @rbs () -> Integer
    def hash
      [@namespace, @key].hash
    end

    # @rbs (Object) -> bool
    def ==(other)
      other.is_a?(self.class) && other.namespace == @namespace && other.key == @key
    end

    alias eql? ==
  end
end
