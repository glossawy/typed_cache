# frozen_string_literal: true

module TypedCache
  # Provides a type-safe, composable namespace abstraction for cache keys.
  #
  # The Namespace class allows you to create hierarchical namespaces for cache keys,
  # ensuring that keys are properly scoped and collisions are avoided. Each Namespace
  # instance can generate cache keys (via #key), create nested namespaces (via #nested),
  # and traverse to parent namespaces (via #parent_namespace).
  #
  # Example:
  #   ns = TypedCache::Namespace.at("users")
  #   ns.key("123") # => #<TypedCache::CacheKey namespace=users key=123>
  #   ns2 = ns.nested("sessions")
  #   ns2.key("abc") # => #<TypedCache::CacheKey namespace=users:sessions key=abc>
  #
  # Namespaces are composable and immutable. The key factory can be customized for advanced use cases.
  class Namespace
    class << self
      # Returns a new Namespace instance rooted at the given namespace string.
      #
      # @param namespace [String] the root namespace
      # @param namespaces [Array<String>] additional namespaces to join
      # @return [Namespace] a new Namespace instance at the given root
      #
      # Example:
      #   TypedCache::Namespace.at("users", "sessions") # => #<TypedCache::Namespace namespace=users:sessions>
      #
      # The returned Namespace can be further nested or used to generate cache keys.
      #
      # @rbs (String, *String) -> Namespace
      def at(namespace, *namespaces)
        root.join(namespace, *namespaces)
      end

      # Returns the root Namespace instance (with an empty namespace).
      #
      # @return [Namespace] the root Namespace
      #
      # Example:
      #   TypedCache::Namespace.root # => #<TypedCache::Namespace namespace=>
      #
      # The root namespace is useful as a starting point for building nested namespaces.
      #
      # @rbs () -> Namespace
      def root
        new(TypedCache.config.default_namespace) { |ns, key| CacheKey.new(ns, key) }
      end
    end

    # Initializes a new Namespace instance with the given namespace string and key factory.
    #
    # @param namespace [String] the namespace string for this instance
    # @param key_factory [Proc] a block that creates CacheKey instances from key strings
    # @yield [key] the key string to create a CacheKey from
    # @yieldreturn [CacheKey] the created cache key
    #
    # Example:
    #   Namespace.new("users") { |key| CacheKey.new("users", key) }
    #
    # @rbs (String) { (Namespace, String) -> CacheKey } -> void
    def initialize(namespace, &key_factory)
      @namespace = namespace
      @key_factory = key_factory
    end

    # Creates a nested namespace by appending the given namespace to the current one.
    #
    # @param namespace [String] the namespace to append
    # @param key_factory [Proc, nil] optional custom key factory for the nested namespace
    # @return [Namespace] a new Namespace instance with the combined namespace
    #
    # Example:
    #   ns = Namespace.at("users")
    #   ns.nested("sessions") # => #<TypedCache::Namespace namespace=users:sessions>
    #
    # If no key_factory is provided, the parent's key factory is inherited.
    #
    # @rbs (String) ?{ (Namespace, String) -> CacheKey } -> Namespace
    def nested(namespace, &key_factory)
      key_factory ||= @key_factory

      self.class.new("#{@namespace}:#{namespace}", &key_factory)
    end

    # Creates a new namespace by joining the current namespace with the given namespaces.
    #
    # @param namespaces [Array<String>] the namespaces to join
    # @param key_factory [Proc, nil] optional custom key factory for the joined namespace
    # @return [Namespace] a new Namespace instance with the combined namespace
    #
    # Example:
    #   ns = Namespace.at("users")
    #   ns.join("sessions", "admin") # => #<TypedCache::Namespace namespace=users:sessions:admin>
    #
    # If no key_factory is provided, the parent's key factory is inherited.
    #
    # @rbs (*String) ?{ (Namespace, String) -> CacheKey } -> Namespace
    def join(*namespaces, &key_factory)
      key_factory ||= @key_factory

      self.class.new("#{@namespace}:#{namespaces.join(":")}", &key_factory)
    end

    # Returns the parent namespace by removing the last namespace segment.
    #
    # @return [Namespace] the parent namespace, or self if already at root
    #
    # Example:
    #   ns = Namespace.at("users:sessions")
    #   ns.parent_namespace # => #<TypedCache::Namespace namespace=users>
    #
    # For root namespaces (empty string), returns self.
    #
    # @rbs () -> Namespace
    def parent_namespace
      return self if @namespace.empty?

      case pathsep_idx = @namespace.rindex(':')
      when nil
        self.class.root
      else
        self.class.new(@namespace[...pathsep_idx])
      end
    end

    # Creates a cache key using the namespace's key factory.
    #
    # @param key [String] the key string to create a cache key from
    # @return [CacheKey] the created cache key
    #
    # Example:
    #   ns = Namespace.at("users")
    #   ns.key("123") # => #<TypedCache::CacheKey namespace=users key=123>
    #
    # @rbs (String) -> CacheKey
    def key(key)
      @key_factory.call(self, key)
    end

    # @rbs () -> bool
    def root? = @namespace.empty?

    # Returns the namespace string representation.
    #
    # @return [String] the namespace string
    #
    # Example:
    #   ns = Namespace.at("users:sessions")
    #   ns.to_s # => "users:sessions"
    #
    # @rbs () -> String
    def to_s
      @namespace
    end

    # Returns a string representation of the Namespace instance for debugging.
    #
    # @return [String] a debug-friendly string representation
    #
    # Example:
    #   ns = Namespace.at("users")
    #   ns.inspect # => "#<TypedCache::Namespace namespace=users>"
    #
    # @rbs () -> String
    def inspect
      "#<#{self.class} #{@namespace}>"
    end

    # @rbs () -> Integer
    def hash
      [@namespace].hash
    end

    # @rbs (Object) -> bool
    def ==(other)
      other.is_a?(self.class) && other.to_s == to_s
    end

    alias eql? ==
  end
end
