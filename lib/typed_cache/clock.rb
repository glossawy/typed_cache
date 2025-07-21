# frozen_string_literal: true

module TypedCache
  # A simple, testable wrapper around Time to provide a consistent way of
  # getting the current time, respecting ActiveSupport's time zone when available.
  class Clock
    class << self
      # Retrieves the current time. If ActiveSupport's `Time.current` is
      # available, it will be used to respect the configured timezone. Otherwise,
      # it falls back to the system's `Time.now`.
      #
      # @return [Time] The current time.
      # @rbs () -> Time
      def moment
        if Time.respond_to?(:current)
          Time.current
        else
          Time.now
        end
      end
    end
  end
end
