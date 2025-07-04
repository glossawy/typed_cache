# frozen_string_literal: true

module TypedCache
  # Generic registry for managing class-based factories
  # @rbs generic T
  class Registry
    # @rbs (String, Hash[Symbol, Class[T]]) -> void
    def initialize(name, defaults = {})
      @name = name
      @registry = defaults.dup
    end

    # @rbs (Symbol, *untyped, **untyped) -> either[Error, T]
    def resolve(key, *, **, &)
      klass = @registry[key]
      return Either.left(ArgumentError.new("Unknown #{@name}: #{key}")) unless klass

      Either.right(klass.new(*, **))
    rescue => e
      Either.left(StoreError.new(
        :"#{@name}_creation",
        key.to_s,
        "Failed to create #{@name} '#{key}': #{e.message}",
        e,
      ))
    end

    # @rbs (Symbol) -> maybe[Class[T]]
    def find(key)
      klass = @registry[key]
      return Maybe.none unless klass

      Maybe.some(klass)
    end

    # @rbs (Symbol, Class[T]) -> either[Error, void]
    def register(key, klass)
      return Either.left(ArgumentError.new("#{@name.capitalize} name cannot be nil")) if key.nil?
      return Either.left(ArgumentError.new("#{@name.capitalize} class cannot be nil")) if klass.nil?

      @registry[key] = klass
      Either.right(nil)
    end

    # @rbs () -> Array[Symbol]
    def available
      @registry.keys
    end

    # @rbs (Symbol) -> bool
    def registered?(key)
      @registry.key?(key)
    end
  end
end
