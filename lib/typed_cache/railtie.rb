# frozen_string_literal: true

module TypedCache
  class Railtie < ::Rails::Railtie
    config.to_prepare do
      # Set the default instrumenter to Rails
      ::TypedCache.configure do |config|
        config.instrumentation.instrumenter = :rails
      end

      # Register the ActiveSupport backend
      ::TypedCache.backends.register(:active_support, ::TypedCache::Instrumenters::ActiveSupport)
    end
  end
end
