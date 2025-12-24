# frozen_string_literal: true

require_relative '../../lib/hoozmo/parser'
require_relative '../../lib/hoozmo/node'

RSpec.describe Hoozmo::Parser do
  describe '.parse' do
    it 'parses single character' do
      ast = described_class.new('a').parse

      expect(ast).to be_a(Hoozmo::Node::Literal)
      expect(ast.value).to eq('a')
    end

    it 'parses multiple characters as concatenation' do
      ast = described_class.new('abc').parse

      expect(ast).to be_a(Hoozmo::Node::Concatenation)
      expect(ast.children.size).to eq(3)
      expect(ast.children[0].value).to eq('a')
      expect(ast.children[1].value).to eq('b')
      expect(ast.children[2].value).to eq('c')
    end

    it 'handles multiple characters' do
      ast = described_class.new('こんにちは').parse

      expect(ast).to be_a(Hoozmo::Node::Concatenation)
      expect(ast.children.size).to eq(5)
      expect(ast.children[0].value).to eq('こ')
      expect(ast.children[1].value).to eq('ん')
    end
  end
end
