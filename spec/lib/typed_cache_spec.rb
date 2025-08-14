# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(TypedCache) do
  before { described_class.reset_config }
  after { described_class.reset_config }

  describe '.builder' do
    it 'returns a CacheBuilder instance' do
      result = described_class.builder
      expect(result).to(be_a(TypedCache::CacheBuilder))
    end
  end

  describe '.configure' do
    it 'accepts a configuration block' do
      expect { |proc| described_class.configure(&proc) }.to(yield_control.once)
    end

    it 'allows setting default_namespace' do
      described_class.configure do |config|
        config.default_namespace = 'test_namespace'
      end
      expect(described_class.config.default_namespace).to(eq('test_namespace'))
    end

    it 'allows setting cache_delimiter' do
      described_class.configure do |config|
        config.cache_delimiter = '|'
      end
      expect(described_class.config.cache_delimiter).to(eq('|'))
    end

    it 'allows settings instrumentation config' do
      described_class.configure do |config|
        config.instrumentation.enabled = true
        config.instrumentation.namespace = 'test_ns'
      end

      expect(described_class.config.instrumentation).to(have_attributes(
        enabled: true,
        namespace: 'test_ns',
      ))
    end

    it 'works without a block' do
      expect { described_class.configure }.not_to(raise_error)
    end
  end

  describe '.backends' do
    let(:backend_class) do
      Class.new do
        include TypedCache::Backend
      end
    end

    let(:register!) { described_class.backends.register(:test_backend, backend_class) }

    it 'registers a new backend type' do
      expect { register! }.not_to(raise_error)
    end

    it 'presents the new backend as available' do
      register!

      expect(described_class.backends.available).to(include(:test_backend))
    end
  end

  describe '.decorators' do
    let(:decorator_class) do
      Class.new do
        include TypedCache::Decorator
      end
    end

    let(:register!) { described_class.decorators.register(:test_decorator, decorator_class) }

    it 'registers a new decorator type' do
      expect { register! }.not_to(raise_error)
    end

    it 'presents the new decorator as available' do
      register!

      expect(described_class.decorators.available).to(include(:test_decorator))
    end
  end
end
