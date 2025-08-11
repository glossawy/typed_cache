# frozen_string_literal: true

require 'spec_helper'

module TypedCache
  RSpec.describe(Snapshot) do
    let(:key) { CacheKey.new('test', 'key') }

    describe '.computed' do
      it 'sets source to computed' do
        snap = described_class.computed(key, 1)
        expect(snap).to(be_computed)
      end
    end

    describe '.updated' do
      it 'sets source to updated' do
        snap = described_class.updated(key, 1)
        expect(snap).to(be_updated)
      end
    end

    describe '.cached' do
      it 'sets source to cache' do
        snap = described_class.cached(key, 1)
        expect(snap).to(be_from_cache)
      end
    end

    describe '#map' do
      it 'preserves metadata' do
        snap = described_class.computed(key, 1)
        newer = snap.map { |v| v + 1 }
        expect(newer.source).to(eq(:computed))
      end
    end

    describe '#age' do
      it 'returns positive number' do
        snap = described_class.computed(key, 0)
        sleep 0.01
        expect(snap.age).to(be > 0)
      end
    end
  end
end
