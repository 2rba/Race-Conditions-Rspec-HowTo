require 'rails_helper'

describe KeyValue do
  self.use_transactional_tests = false
  let(:key) { 'key' }
  before do
    KeyValue.delete_all
  end

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
        let(:first) { KeyValue }
        let(:second) { KeyValue.dup }

        it 'handle double create race condition' do
          expect do
            ConditionRacer.new(first: first,
                               second: second,
                               method_name: :read_record).run do |obj|
              obj.inc(key)
            end
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
        let(:first) { KeyValue }
        let(:second) { KeyValue.dup }

        it 'handle double update race condition' do
          ConditionRacer.new(first: first,
                             second: second,
                             method_name: :read_record).run do |obj|
            obj.inc(key)
          end

          expect(KeyValue.first.value).to eq(2)
        end
      end
    end
  end
end
