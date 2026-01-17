# frozen_string_literal: true

require_relative '../../../lib/hoozmo'
require_relative '../../../lib/hoozmo/automaton'

RSpec.describe Hoozmo::Automaton::NFA do
  describe '.new_from_node' do
    it 'builds NFA from literal node' do
      node = Hoozmo::Node::Literal.new('a')
      state = Hoozmo::Automaton::StateID.new(0)

      nfa = described_class.new_from_node(node, state)

      expect(nfa.start).to be_a(Hoozmo::Automaton::StateID)
      expect(nfa.accept).to be_an(Array)
      expect(nfa.accept.length).to eq(1)
      expect(nfa.transitions.size).to eq(1)
    end

    it 'builds NFA from Epsilon node' do
      node = Hoozmo::Node::Epsilon.new
      state = Hoozmo::Automaton::StateID.new(0)

      nfa = described_class.new_from_node(node, state)

      expect(nfa.start).to be_a(Hoozmo::Automaton::StateID)
      expect(nfa.accept.length).to eq(1)
      # ε 遷移が1つあるはず
      epsilon_transitions = nfa.transitions.select { |_, label, _| label.nil? }
      expect(epsilon_transitions.size).to eq(1)
    end

    it 'builds NFA from Concatenation node' do
      node = Hoozmo::Node::Concatenation.new([
                                               Hoozmo::Node::Literal.new('a'),
                                               Hoozmo::Node::Literal.new('b')
                                             ])
      state = Hoozmo::Automaton::StateID.new(0)

      nfa = described_class.new_from_node(node, state)

      expect(nfa.start).to be_a(Hoozmo::Automaton::StateID)
      expect(nfa.accept.length).to eq(1)
      # 2つの文字遷移 + 1つの ε 遷移（連結用）
      expect(nfa.transitions.size).to be >= 3
    end

    it 'builds NFA from Choice node' do
      node = Hoozmo::Node::Choice.new([
                                        Hoozmo::Node::Literal.new('a'),
                                        Hoozmo::Node::Literal.new('b')
                                      ])
      state = Hoozmo::Automaton::StateID.new(0)

      nfa = described_class.new_from_node(node, state)

      expect(nfa.start).to be_a(Hoozmo::Automaton::StateID)
      expect(nfa.accept.length).to eq(2)
      # 2つの文字遷移 + 2つの ε 遷移（選択用）
      epsilon_transitions = nfa.transitions.select { |_, label, _| label.nil? }
      expect(epsilon_transitions.size).to eq(2)
    end

    it 'builds NFA from Repetition node' do
      node = Hoozmo::Node::Repetition.new(
        Hoozmo::Node::Literal.new('a'),
        :zero_or_more
      )
      state = Hoozmo::Automaton::StateID.new(0)

      nfa = described_class.new_from_node(node, state)

      expect(nfa.start).to be_a(Hoozmo::Automaton::StateID)
      expect(nfa.accept.length).to eq(1)
      # ε 遷移によるループ構造があるはず
      epsilon_transitions = nfa.transitions.select { |_, label, _| label.nil? }
      expect(epsilon_transitions.size).to be >= 4 # 最低4つのε 遷移
    end
  end

  describe '#epsilon_closure' do
    it 'computes epsilon closure of a single state' do
      state = Hoozmo::Automaton::StateID.new(0)
      s0 = state.new_state
      s1 = state.new_state
      s2 = state.new_state

      nfa = described_class.new(s0, [s2])
      nfa.add_epsilon_transition(s0, s1)
      nfa.add_epsilon_transition(s1, s2)

      closure = nfa.epsilon_closure(Set[s0])
      expect(closure).to include(s0, s1, s2)
    end
  end

  describe '#match?' do
    it 'matches a single character' do
      node = Hoozmo::Node::Literal.new('a')
      state = Hoozmo::Automaton::StateID.new(0)
      nfa = described_class.new_from_node(node, state)

      expect(nfa.match?('a')).to be true
      expect(nfa.match?('b')).to be false
      expect(nfa.match?('')).to be false
    end

    it 'matches concatenation' do
      node = Hoozmo::Node::Concatenation.new([
                                               Hoozmo::Node::Literal.new('a'),
                                               Hoozmo::Node::Literal.new('b')
                                             ])
      state = Hoozmo::Automaton::StateID.new(0)
      nfa = described_class.new_from_node(node, state)

      expect(nfa.match?('ab')).to be true
      expect(nfa.match?('a')).to be false
      expect(nfa.match?('b')).to be false
      expect(nfa.match?('abc')).to be false
    end

    it 'matches choice' do
      node = Hoozmo::Node::Choice.new([
                                        Hoozmo::Node::Literal.new('a'),
                                        Hoozmo::Node::Literal.new('b')
                                      ])
      state = Hoozmo::Automaton::StateID.new(0)
      nfa = described_class.new_from_node(node, state)

      expect(nfa.match?('a')).to be true
      expect(nfa.match?('b')).to be true
      expect(nfa.match?('c')).to be false
      expect(nfa.match?('ab')).to be false
    end

    it 'matches repetition pattern' do
      node = Hoozmo::Node::Repetition.new(
        Hoozmo::Node::Literal.new('a'),
        :zero_or_more
      )
      state = Hoozmo::Automaton::StateID.new(0)
      nfa = described_class.new_from_node(node, state)

      expect(nfa.match?('')).to be true     # 0回
      expect(nfa.match?('a')).to be true    # 1回
      expect(nfa.match?('aaa')).to be true  # 3回
      expect(nfa.match?('b')).to be false   # マッチしない
    end
  end
end
