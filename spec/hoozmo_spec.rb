# frozen_string_literal: true

require_relative '../lib/hoozmo'

RSpec.describe Hoozmo do
  describe '#match?' do
    context 'with exact match pattern' do
      let(:hoozmo) { Hoozmo.new('abc') }
      
      it 'matches exact string' do
        expect(hoozmo.match?('abc')).to be true
      end

      it 'does not match shorter string' do
        expect(hoozmo.match?('ab')).to be false
      end

      it 'does not match longer string' do
        expect(hoozmo.match?('abcd')).to be false
      end

      it 'matches empty string' do
        regex = Hoozmo.new('')
        expect(regex.match?('')).to be true
      end

      it 'does not match empty pattern with non-empty input' do
        regex = Hoozmo.new('')
        expect(regex.match?('a')).to be false
      end

      it 'matches multibyte characters' do
        regex = Hoozmo.new('こんにちは')
        expect(regex.match?('こんにちは')).to be true
        expect(regex.match?('さようなら')).to be false
      end
    end
  end
end
