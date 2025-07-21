# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(TypedCache::Clock) do
  describe '.moment' do
    let(:now_time) { Time.now }
    let(:current_time) { Time.now - 100 } # A distinctly different time

    context 'when Time does not respond to :current' do
      before do
        allow(Time).to(receive(:respond_to?).and_call_original)
        allow(Time).to(receive(:respond_to?).with(:current).and_return(false))
        allow(Time).to(receive(:now).and_return(now_time))
      end

      it 'returns the result of Time.now' do
        expect(described_class.moment).to(eq(now_time))
      end
    end

    context 'when Time responds to :current' do
      before do
        allow(Time).to(receive(:respond_to?).and_call_original)
        allow(Time).to(receive(:respond_to?).with(:current).and_return(true))
        allow(Time).to(receive(:current).and_return(current_time))
        allow(Time).to(receive(:now)) # Prevent :now from being called
      end

      it 'returns the result of Time.current' do
        expect(described_class.moment).to(eq(current_time))
      end

      it 'does not call Time.now' do
        described_class.moment
        expect(Time).not_to(have_received(:now))
      end
    end
  end
end
