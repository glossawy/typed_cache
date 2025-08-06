# typed: strict

module TypedCache
  module Private
    class Configuration < BasicObject
      class Instrumentation < BasicObject
        sig { returns(T::Boolean) }
        attr_accessor :enabled

        sig { returns(String) }
        attr_accessor :namespace

        sig { returns(Symbol) }
        attr_accessor :instrumenter
      end

      sig { returns(String) }
      attr_accessor :namespace

      sig { returns(::TypedCache::Private::Configuration::Instrumentation) }
      def instrumentation; end
    end
  end

  class << self
    sig { params(block: T.proc.params(config: ::TypedCache::Private::Configuration).void).void }
    def configure(&block); end

    sig { returns(::TypedCache::Private::Configuration) }
    def config; end

    sig { returns(::TypedCache::CacheBuilder) }
    def builder; end

    sig { returns(T.class_of(::TypedCache::Backends)) }
    def backends; end

    sig { returns(T.class_of(::TypedCache::Decorators)) }
    def decorators; end

    sig { returns(T.class_of(::TypedCache::Instrumenters)) }
    def instrumenters; end
  end

  private_constant :Backends, :Decorators, :Instrumenters
end
