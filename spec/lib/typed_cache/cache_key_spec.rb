# frozen_string_literal: true

require 'spec_helper'

module TypedCache
  RSpec.describe(CacheKey) do
    include Namespacing

    let(:namespace) { make_namespace('cache_key_spec') }

    describe '#initialize' do
      it 'creates a new cache key' do
        key = described_class.new(namespace, 'my_key')
        expect(key.namespace).to(eq(namespace))
        expect(key.key).to(eq('my_key'))
      end
    end

    describe '#to_s' do
      it 'returns a string representation of the key' do
        key = described_class.new(namespace, 'my_key')
        expect(key.to_s).to(eq("#{namespace}:my_key"))
      end
    end

    describe '#inspect' do
      it 'returns a debug-friendly string' do
        key = described_class.new(namespace, 'my_key')
        expect(key.inspect).to(eq("#<TypedCache::CacheKey namespace=#{namespace} key=my_key>"))
      end
    end

    describe '#==' do
      it 'returns true for equal keys' do
        key1 = described_class.new(namespace, 'my_key')
        key2 = described_class.new(namespace, 'my_key')
        expect(key1).to(eq(key2))
      end

      it 'returns false for different namespaces' do
        other_namespace = make_namespace('other_spec')
        key1 = described_class.new(namespace, 'my_key')
        key2 = described_class.new(other_namespace, 'my_key')
        expect(key1).not_to(eq(key2))
      end

      it 'returns false for different keys' do
        key1 = described_class.new(namespace, 'my_key')
        key2 = described_class.new(namespace, 'other_key')
        expect(key1).not_to(eq(key2))
      end
    end

    describe '#hash' do
      it 'is the same for equal keys' do
        key1 = described_class.new(namespace, 'my_key')
        key2 = described_class.new(namespace, 'my_key')
        expect(key1.hash).to(eq(key2.hash))
      end

      it 'is different for different keys' do
        key1 = described_class.new(namespace, 'my_key')
        key2 = described_class.new(namespace, 'other_key')
        expect(key1.hash).not_to(eq(key2.hash))
      end
    end

    describe '#belongs_to?' do
      let(:parent) { make_namespace('parent') }
      let(:child) { parent.nested('child') }
      let(:unrelated) { make_namespace('unrelated') }

      it 'returns true for its own namespace' do
        key = described_class.new(child, 'my_key')
        expect(key.belongs_to?(child)).to(be(true))
      end

      it 'returns true for a parent namespace' do
        key = described_class.new(child, 'my_key')
        expect(key.belongs_to?(parent)).to(be(true))
      end

      it 'returns false for an unrelated namespace' do
        key = described_class.new(child, 'my_key')
        expect(key.belongs_to?(unrelated)).to(be(false))
      end
    end
  end
end
