# frozen_string_literal: true

require_relative '../lib/hoozmo'

RSpec.describe Hoozmo do
  describe '#match?' do
    context 'with exact match pattern' do
      let(:hoozmo) { described_class.new('abc') }

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
        regex = described_class.new('')
        expect(regex.match?('')).to be true
      end

      it 'does not match empty pattern with non-empty input' do
        regex = described_class.new('')
        expect(regex.match?('a')).to be false
      end

      it 'matches multibyte characters' do
        regex = described_class.new('こんにちは')
        expect(regex.match?('こんにちは')).to be true
        expect(regex.match?('さようなら')).to be false
      end
    end

    context 'with choice pattern' do
      let(:regex) { described_class.new('a|b') }

      it 'matches first choice' do
        expect(regex.match?('a')).to be true
      end

      it 'matches second choice' do
        expect(regex.match?('b')).to be true
      end

      it 'does not match both choices concatenated' do
        expect(regex.match?('ab')).to be false
      end

      it 'does not match neither choice' do
        expect(regex.match?('c')).to be false
      end
    end

    context 'with complex choice pattern' do
      let(:regex) { described_class.new('cat|dog') }

      it 'matches first choice' do
        expect(regex.match?('cat')).to be true
      end

      it 'matches second choice' do
        expect(regex.match?('dog')).to be true
      end

      it 'does not match partial match' do
        expect(regex.match?('ca')).to be false
        expect(regex.match?('do')).to be false
      end
    end

    context 'with multiple choices' do
      let(:regex) { described_class.new('red|green|blue') }

      it 'matches all choices' do
        expect(regex.match?('red')).to be true
        expect(regex.match?('green')).to be true
        expect(regex.match?('blue')).to be true
      end
    end
  end

  context 'with grouped patterns' do
    it 'matches pattern with simple grouping' do
      regex = described_class.new('a(b|c)d')

      expect(regex.match?('abd')).to be true
      expect(regex.match?('acd')).to be true
      expect(regex.match?('ad')).to be false
      expect(regex.match?('abcd')).to be false
    end

    it 'matches pattern with nested grouping' do
      regex = described_class.new('a((b|c)|d)e')

      expect(regex.match?('abe')).to be true
      expect(regex.match?('ace')).to be true
      expect(regex.match?('ade')).to be true
      expect(regex.match?('ae')).to be false
    end

    it 'matches pattern with empty alternative' do
      regex = described_class.new('ab(cd|)ef')

      expect(regex.match?('abcdef')).to be true
      expect(regex.match?('abef')).to be true
    end

    it 'matches complex pattern' do
      regex = described_class.new('(a|b)(c|d)')

      expect(regex.match?('ac')).to be true
      expect(regex.match?('ad')).to be true
      expect(regex.match?('bc')).to be true
      expect(regex.match?('bd')).to be true
      expect(regex.match?('ab')).to be false
      expect(regex.match?('cd')).to be false
    end
  end

  context 'with zero-or-more reprtition' do
    context 'with pattern a*' do
      let(:regex) { described_class.new('a*') }

      it 'matches empty string' do
        expect(regex.match?('')).to be true
      end

      it 'matches single character' do
        expect(regex.match?('a')).to be true
      end

      it 'matches multiple characters' do
        expect(regex.match?('aaa')).to be true
      end

      it 'does not match different character' do
        expect(regex.match?('b')).to be false
      end
    end

    context 'with pattern (ab)*c' do
      let(:regex) { described_class.new('(ab)*') }

      it 'matches empty string' do
        expect(regex.match?('')).to be true
      end

      it 'matches single repetition' do
        expect(regex.match?('ab')).to be true
      end

      it 'matches multiple repetitions' do
        expect(regex.match?('ababab')).to be true
      end

      it 'does not match partial match' do
        expect(regex.match?('aba')).to be false
      end
    end

    context 'with complex pattern' do
      let(:regex) { described_class.new('a(bc|de)*f') }

      it 'matches with zero repetitions' do
        expect(regex.match?('af')).to be true
      end

      it 'matches with one repetition' do
        expect(regex.match?('abcf')).to be true
        expect(regex.match?('adef')).to be true
      end

      it 'matches with multiple repetitions' do
        expect(regex.match?('abcdef')).to be true
        expect(regex.match?('abcbcdef')).to be true
        expect(regex.match?('adedef')).to be true
      end

      it 'does not match incomplete pattern' do
        expect(regex.match?('a')).to be false
        expect(regex.match?('abc')).to be false
        expect(regex.match?('abcde')).to be false
      end
    end
  end
end
