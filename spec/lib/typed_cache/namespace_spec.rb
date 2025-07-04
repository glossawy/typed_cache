# frozen_string_literal: true

require 'spec_helper'

module TypedCache
  RSpec.describe(Namespace) do
    before do
      TypedCache.configure do |config|
        config.default_namespace = 'test'
      end
    end

    after { TypedCache.reset_config }

    describe '.at' do
      it 'returns a top-level namespace with given segment' do
        ns = described_class.at('users')
        expect(ns.to_s).to(eq('test:users'))
      end
    end

    describe '#nested' do
      let(:root) { described_class.at('users') }

      it 'returns nested namespace string' do
        nested = root.nested('sessions')
        expect(nested.to_s).to(eq('test:users:sessions'))
      end

      it 'does not modify the original namespace' do
        root.nested('sessions')
        expect(root.to_s).to(eq('test:users'))
      end
    end

    describe '#parent_namespace' do
      it 'returns the parent when not at root' do
        child = described_class.at('a:b:c')
        expect(child.parent_namespace.to_s).to(eq('test:a:b'))
      end

      it 'returns the root namespace for a top-level namespace' do
        root = described_class.at('a')
        expect(root.parent_namespace).to(eq(described_class.root))
      end

      it 'returns self for root namespace' do
        root = described_class.root
        expect(root.parent_namespace).to(eq(root))
      end
    end

    describe '#key' do
      let(:ns) { described_class.at('users') }

      it 'returns a CacheKey instance' do
        key = ns.key('123')
        expect(key).to(be_a(CacheKey))
      end

      it 'prefixes key with namespace' do
        key = ns.key('123')
        expect(key.to_s).to(eq('test:users:123'))
      end
    end
  end
end
