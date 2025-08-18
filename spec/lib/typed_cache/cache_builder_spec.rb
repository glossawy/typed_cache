# frozen_string_literal: true

require 'spec_helper'

module TypedCache
  RSpec.describe(CacheBuilder) do
    include Namespacing

    let(:namespace) { make_namespace('cache_builder_spec') }
    let(:backend_name) { :memory }
    let(:backend_args) { [] }
    let(:backend_options) { {} }
    let(:decorator_configs) { [] }
    let(:instrumenter_source) { nil }

    let(:builder) do
      builder = TypedCache.builder.with_backend(backend_name, *backend_args, **backend_options)
      decorator_configs.each do |config|
        builder = builder.with_decorator(config.name, **config.options)
      end
      builder = builder.with_instrumentation(instrumenter_source) if instrumenter_source
      builder
    end

    let(:store) { builder.build!(namespace) }
    let(:backend) { store.backend }

    describe '#build_backend' do
      it 'builds a backend' do
        expect(builder.build_backend).to(be_right.with(be_a(Backends::Memory)))
      end

      it 'returns a Left if the build fails' do
        builder = TypedCache.builder.with_backend(:invalid)
        expect(builder.build_backend).to(be_left.with(ArgumentError))
      end
    end

    describe '#build_backend!' do
      it 'builds a backend' do
        expect(builder.build_backend!).to(be_a(Backends::Memory))
      end

      it 'raises an error if the build fails' do
        builder = TypedCache.builder.with_backend(:invalid)
        expect { builder.build_backend! }.to(raise_error(ArgumentError))
      end
    end

    describe '#build!' do
      it 'builds a store' do
        expect(store).to(be_a(Store))
      end

      it 'raises an error if the build fails' do
        builder = TypedCache.builder.with_backend(:invalid)
        expect { builder.build!(namespace) }.to(raise_error(ArgumentError))
      end
    end

    describe '#build' do
      it 'builds a store without decorators' do
        expect(backend).to(be_a(Backends::Memory))
      end

      it 'returns a Left if the build fails' do
        builder = TypedCache.builder.with_backend(:invalid)
        expect(builder.build(namespace)).to(be_left.with(ArgumentError))
      end
    end

    describe '#with_decorator' do
      let(:decorator_configs) do
        [
          ::TypedCache::DecoratorConfig.new(name: :instrumented, options: {
            instrumenter: Instrumenters::Null.new(namespace: 'test'),
          }),
        ]
      end

      it 'builds a store with a decorator' do
        decorator = backend
        expect(decorator).to(be_a(Decorators::Instrumented))
      end

      it 'the decorator wraps the backend' do
        expect(backend.backend).to(be_a(Backends::Memory))
      end

      context 'with a custom decorator' do
        let(:decorator_class) do
          Class.new do
            include Decorator
            attr_reader :backend

            def initialize(backend, **)
              @backend = backend
            end

            def read(key)
              result = super

              "decorated_#{result}" if result
            end
          end
        end
        let(:decorator_configs) { [::TypedCache::DecoratorConfig.new(name: :custom, options: {})] }

        before { Decorators.register(:custom, decorator_class) }

        it 'applies the decorator' do
          store.write('k', 'v')
          result = store.read('k')
          expect(result).to(be_cached_value(some('decorated_v')))
        end
      end
    end

    describe '#with_instrumentation' do
      context 'with the rails instrumenter' do
        let(:instrumenter_source) { :rails }

        it 'applies the instrumented decorator' do
          expect(backend).to(be_a(Decorators::Instrumented))
        end

        it 'applies the correct instrumenter type' do
          expect(backend.instrumenter).to(be_a(Instrumenters::ActiveSupport))
        end
      end

      context 'with the dry-monitor instrumenter' do
        let(:instrumenter_source) { :dry }

        it 'applies the instrumented decorator' do
          expect(backend).to(be_a(Decorators::Instrumented))
        end

        it 'applies the correct instrumenter type' do
          expect(backend.instrumenter).to(be_a(Instrumenters::Monitor))
        end
      end

      context 'with the null instrumenter by default' do
        let(:instrumenter_source) { :default }

        it 'applies the instrumented decorator' do
          expect(backend).to(be_a(Decorators::Instrumented))
        end

        it 'applies the correct instrumenter type' do
          expect(backend.instrumenter).to(be_a(Instrumenters::Null))
        end
      end

      context 'with a custom instrumenter instance' do
        let(:instrumenter_source) { Instrumenters::Null.new(namespace: 'custom') }

        it 'accepts a custom instrumenter instance' do
          expect(backend.instrumenter).to(be(instrumenter_source))
        end
      end

      context 'with an invalid source' do
        let(:instrumenter_source) { :invalid }

        it 'returns a Left' do
          result = builder.build(namespace)
          expect(result).to(be_a(TypedCache::Left))
        end
      end
    end
  end
end
