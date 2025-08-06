# frozen_string_literal: true

module TypedCache
  # Base error class for TypedCache operations
  class Error < StandardError
    # @rbs (*untyped) -> void
    def initialize(*args)
      super(*args)
      set_backtrace(caller(2))
    end
  end

  # Store operation errors (network, I/O, etc.)
  class StoreError < Error
    attr_reader :operation, :key, :original_error

    # @rbs (Symbol, String, String, Exception?) -> void
    def initialize(operation, key, message, original_error = nil)
      super(message)
      @operation = operation
      @key = key
      @original_error = original_error

      set_backtrace(original_error.backtrace) if original_error
    end

    # @rbs () -> String
    def detailed_message
      base = "#{operation.upcase} operation failed for key '#{key}': #{message}"
      original_error ? "#{base} (#{original_error.class}: #{original_error.message})" : base
    end

    # @rbs () -> bool
    def has_cause?
      !@original_error.nil?
    end
  end

  # Type safety violations
  class TypeError < Error
    attr_reader :expected_type, :actual_type, :value

    # @rbs (String, String, untyped, String) -> void
    def initialize(expected_type, actual_type, value, message)
      super(message)
      @expected_type = expected_type
      @actual_type = actual_type
      @value = value
    end

    # @rbs () -> String
    def type_mismatch_message
      "Expected #{expected_type}, got #{actual_type}"
    end
  end

  # Cache miss (when expecting a value to exist)
  class CacheMissError < Error
    attr_reader :key

    # @rbs (CacheKey) -> void
    def initialize(key)
      super("Cache miss for key: #{key}")
      @key = key
    end

    # @rbs () -> bool
    def cache_miss?
      true
    end
  end
end
