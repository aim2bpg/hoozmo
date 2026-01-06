# frozen_string_literal: true

require_relative '../../lib/hoozmo/parser'
require_relative '../../lib/hoozmo/node'

RSpec.describe Hoozmo::Parser do
  describe '#parse' do
    it 'parses single character' do
      ast = described_class.new('a').parse

      expect(ast).to be_a(Hoozmo::Node::Literal)
      expect(ast.value).to eq('a')
    end

    it 'parses multiple characters as concatenation' do
      ast = described_class.new('abc').parse

      expect(ast).to be_a(Hoozmo::Node::Concatenation)
      expect(ast.children.length).to eq(3)
      expect(ast.children[0].value).to eq('a')
      expect(ast.children[1].value).to eq('b')
      expect(ast.children[2].value).to eq('c')
    end

    it 'handles multiple characters' do
      ast = described_class.new('こんにちは').parse

      expect(ast).to be_a(Hoozmo::Node::Concatenation)
      expect(ast.children.length).to eq(5)
      expect(ast.children[0].value).to eq('こ')
      expect(ast.children[1].value).to eq('ん')
    end

    it 'parses choice pattern' do
      ast = described_class.new('a|b').parse

      expect(ast).to be_a(Hoozmo::Node::Choice)
      expect(ast.children.length).to eq(2)
      expect(ast.children[0]).to be_a(Hoozmo::Node::Literal)
      expect(ast.children[0].value).to eq('a')
      expect(ast.children[1]).to be_a(Hoozmo::Node::Literal)
      expect(ast.children[1].value).to eq('b')
    end

    it 'parases choice with concatenation' do
      ast = described_class.new('cat|dog').parse

      expect(ast).to be_a(Hoozmo::Node::Choice)
      expect(ast.children.length).to eq(2)

      cat = ast.children[0]
      expect(cat).to be_a(Hoozmo::Node::Concatenation)
      expect(cat.children.size).to eq(3)
      expect(cat.children[0].value).to eq('c')
      expect(cat.children[1].value).to eq('a')
      expect(cat.children[2].value).to eq('t')

      dog = ast.children[1]
      expect(dog).to be_a(Hoozmo::Node::Concatenation)
      expect(dog.children.size).to eq(3)
      expect(dog.children[0].value).to eq('d')
      expect(dog.children[1].value).to eq('o')
      expect(dog.children[2].value).to eq('g')
    end

    it 'parses multiple choices' do
      ast = described_class.new('a|b|c').parse

      expect(ast).to be_a(Hoozmo::Node::Choice)
      expect(ast.children.length).to eq(3)
    end
  end

  context 'with grouping' do
    it 'parses simple grouped pattern' do
      ast = described_class.new('a(b|c)d').parse

      expect(ast).to be_a(Hoozmo::Node::Concatenation)
      expect(ast.children.length).to eq(3)

      # 'a'
      expect(ast.children[0]).to be_a(Hoozmo::Node::Literal)
      expect(ast.children[0].value).to eq('a')

      # '(b|c)'
      choice = ast.children[1]
      expect(choice).to be_a(Hoozmo::Node::Choice)
      expect(choice.children.length).to eq(2)
      expect(choice.children[0].value).to eq('b')
      expect(choice.children[1].value).to eq('c')

      # 'd'
      expect(ast.children[2]).to be_a(Hoozmo::Node::Literal)
      expect(ast.children[2].value).to eq('d')
    end

    it 'parses nested groups' do
      ast = described_class.new('a((b|c)|d)e').parse

      expect(ast).to be_a(Hoozmo::Node::Concatenation)
      expect(ast.children.length).to eq(3)

      # 中央の複雑なグループ
      outer_choice = ast.children[1]
      expect(outer_choice).to be_a(Hoozmo::Node::Choice)
      expect(outer_choice.children.length).to eq(2)

      # 内側のグループ (b|c)
      inner_choice = outer_choice.children[0]
      expect(inner_choice).to be_a(Hoozmo::Node::Choice)
    end

    it 'parses group with empty alternative' do
      ast = described_class.new('ab(cd|)ef').parse

      expect(ast).to be_a(Hoozmo::Node::Concatenation)

      # グループ部分
      choice = ast.children[2]
      expect(choice).to be_a(Hoozmo::Node::Choice)
      expect(choice.children.length).to eq(2)

      # 空の選択肢
      expect(choice.children[1]).to be_a(Hoozmo::Node::Epsilon)
    end
  end

  context 'with error cases' do
    it 'raises error for unmatched opening parenthesis' do
      expect do
        described_class.new('a(b').parse
      end.to raise_error(/Expected closing parenthesis/)
    end

    it 'raises error for unmatched closing parenthesis' do
      expect do
        described_class.new('a)b').parse
      end.to raise_error(/Unexpected character/)
    end

    it 'raises error for nested unmatched parentheses' do
      expect do
        described_class.new('a((b|c)').parse
      end.to raise_error(/Expected closing parenthesis/)
    end
  end
end
