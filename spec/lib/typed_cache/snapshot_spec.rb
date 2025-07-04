# frozen_string_literal: true

require 'spec_helper'

module TypedCache
  RSpec.describe(Snapshot) do
    describe '.computed' do
      it 'sets source to computed' do
        snap = described_class.computed(1)
        expect(snap.computed?).to(be(true))
      end
    end

    describe '#map' do
      it 'preserves metadata' do
        snap = described_class.computed(1)
        newer = snap.map { |v| v + 1 }
        expect(newer.source).to(eq(:computed))
      end
    end

    describe '#age' do
      it 'returns positive number' do
        snap = described_class.computed(0)
        sleep 0.01
        expect(snap.age).to(be > 0)
      end
    end
  end
end
