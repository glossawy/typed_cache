# typed: strict

module TypedCache
  module Private
    class Configuration < BasicObject
      class Instrumentation < BasicObject
        sig { returns(T::Boolean) }
        attr_accessor :enabled

        sig { returns(Symbol) }
        attr_accessor :instrumenter
      end

      sig { returns(String) }
      attr_accessor :namespace

      sig { returns(Configuration::Instrumentation) }
      def instrumentation; end
    end
  end

  class << self
    sig { params(block: T.proc.params(config: Private::Configuration).void).void }
    def configure(&block); end

    sig { returns(Private::Configuration) }
    def config; end

    sig { returns(CacheBuilder) }
    def builder; end

    sig { returns(T.class_of(Backends)) }
    def backends; end

    sig { returns(T.class_of(Decorators)) }
    def decorators; end

    sig { returns(T.class_of(Instrumenters)) }
    def instrumenters; end
  end
end
