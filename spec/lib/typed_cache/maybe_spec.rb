# frozen_string_literal: true

require 'spec_helper'

module TypedCache
  RSpec.describe(Maybe) do
    describe '.some?' do
      it 'returns true for Some' do
        expect(Maybe.some(1).some?).to(be(true))
      end
    end

    describe '.nothing?' do
      it 'returns true for Nothing' do
        expect(Maybe.none.nothing?).to(be(true))
      end
    end

    describe '#map' do
      it 'transforms Some' do
        res = Maybe.some(2).map { |v| v * 2 }
        expect(res.value).to(eq(4))
      end

      it 'returns Nothing unchanged' do
        res = Maybe.none.map { raise }
        expect(res.nothing?).to(be(true))
      end
    end
  end
end
