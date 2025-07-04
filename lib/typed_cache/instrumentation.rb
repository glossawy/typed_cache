# frozen_string_literal: true

require 'dry/configurable'

module TypedCache
  # Instrumentation hooks for ActiveSupport::Notifications integration
  # All instrumentation is explicit and opt-in - no automatic behavior
  module Instrumentation
    class << self
      # @rbs! type config = TypedCache::_TypedCacheInstrumentationConfig

      # @rbs () -> config
      def config
        TypedCache.config.instrumentation
      end

      # Check if ActiveSupport::Notifications is available
      # @rbs () -> bool
      def notifications_available?
        defined?(ActiveSupport::Notifications)
      end

      # Main instrumentation method
      #: [T] (String, String, String, Hash[Symbol, untyped]) { -> T } -> T
      def instrument(operation, namespace, key, payload = {})
        return yield unless config.enabled && notifications_available?

        event_name = "#{operation}.#{config.namespace}"
        start_time = current_time

        begin
          result = yield

          # Determine success and extract metadata
          success, snapshot_data = extract_result_metadata(result)

          final_payload = base_payload(namespace, key, start_time).merge(payload).merge({
            success: success,
            **snapshot_data,
          })

          ActiveSupport::Notifications.instrument(event_name, final_payload) do
            # This block is called by subscribers who want the result
            result
          end

          result
        rescue => error
          error_payload = base_payload(namespace, key, start_time).merge(payload).merge({
            success: false,
            error: error.class.name,
            error_message: error.message,
          })

          ActiveSupport::Notifications.instrument(event_name, error_payload)
          raise
        end
      end

      private

      # Cross-platform current time helper (uses Time.current when available)
      #: -> Time
      def current_time
        if Time.respond_to?(:current)
          Time.current
        else
          Time.now
        end
      end

      # @rbs (String, String, Time) -> Hash[Symbol, untyped]
      def base_payload(namespace, key, start_time)
        {
          namespace: namespace,
          key: key,
          duration: (current_time - start_time) * 1000.0, # milliseconds
          store_type: nil, # Will be set by caller if available
        }
      end

      # @rbs (Either[StandardError, Snapshot]) -> [bool, Hash[Symbol, untyped]]
      def extract_result_metadata(result)
        case result
        when Either
          if result.right?
            snapshot = result.value
            if snapshot.is_a?(Snapshot)
              [true, {
                cache_hit: snapshot.from_cache?,
                cache_miss: !snapshot.from_cache?,
                source: snapshot.source,
                snapshot_age: snapshot.age,
              },]
            else
              [true, { cache_hit: false, cache_miss: true }]
            end
          else
            error_data = {
              cache_hit: false,
              cache_miss: true,
              error_type: result.error.class.name,
            }
            [false, error_data]
          end
        else
          [true, {}]
        end
      end
    end
  end
end
