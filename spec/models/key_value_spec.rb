require 'rails_helper'

describe KeyValue do
  include TransactionHelpers

  let(:key) { 'key' }

  describe '.inc' do
    context 'when new data' do
      it 'should store data as a new record' do
        expect do
          KeyValue.inc(key)
        end.to change { KeyValue.count }.by(1)

        expect(KeyValue.first.key).to eq(key)
        expect(KeyValue.first.value).to eq(1)
      end

      context 'with race conditions' do
        let(:concurrent_thread) do
          wait_for_thread_warmup(Thread.new { KeyValue.inc(key) })
        end

        concurrent_transactions_enabled

        before do
          allow(KeyValue).to receive(:read_record)
                               .and_wrap_original(&call_once_concurrent_thread)
        end

        it 'handles double create race condition' do
          expect do
            KeyValue.inc(key)
            concurrent_thread.join
          end.not_to raise_exception

          expect(KeyValue.count).to eq(1)
          expect(KeyValue.first.value).to eq(2)
        end
      end
    end

    context 'when data exists' do
      before do
        KeyValue.create(key: key, value: 0)
      end

      it 'should update existing record' do
        KeyValue.inc(key)

        expect(KeyValue.count).to eq(1)
        expect(KeyValue.first.value).to eq(1)
      end

      context 'with race conditions' do
        let(:concurrent_thread) do
          wait_for_thread_warmup(Thread.new { KeyValue.inc(key) })
        end

        concurrent_transactions_enabled

        before do
          allow(KeyValue).to receive(:read_record).and_wrap_original(&call_once_concurrent_thread)
        end

        it 'handles double update race condition' do
          expect do
            KeyValue.inc(key)
            concurrent_thread.join
          end.not_to raise_exception

          expect(KeyValue.first.value).to eq(2)
        end
      end
    end
  end
end
