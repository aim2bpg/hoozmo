# frozen_string_literal: true

require_relative '../../../lib/hoozmo'
require_relative '../../../lib/hoozmo/automaton'

RSpec.describe Hoozmo::Automaton::DFA do
  describe '.from_nfa' do
    it 'converts simple NFA to DFA' do
      # NFAを構築: パターン 'a'
      node = Hoozmo::Node::Literal.new('a')
      state = Hoozmo::Automaton::StateID.new(0)
      nfa = Hoozmo::Automaton::NFA.new_from_node(node, state)

      # DFAに変換
      dfa = described_class.from_nfa(nfa)

      expect(dfa.start).to be_an(Integer)
      expect(dfa.accept).to be_a(Set)
      expect(dfa.accept).not_to be_empty
      expect(dfa.transitions).not_to be_empty
    end

    it 'converts choice NFA to DFA' do
      # NFAを構築: パターン 'a|b'
      node = Hoozmo::Node::Choice.new([
                                        Hoozmo::Node::Literal.new('a'),
                                        Hoozmo::Node::Literal.new('b')
                                      ])
      state = Hoozmo::Automaton::StateID.new(0)
      nfa = Hoozmo::Automaton::NFA.new_from_node(node, state)

      # DFAに変換
      dfa = described_class.from_nfa(nfa)

      expect(dfa.start).to be_an(Integer)
      expect(dfa.accept.size).to be >= 1
      # 'a' と 'b' の両方の遷移があるはず
      transitions_chars = dfa.transitions.map { |_, chars, _| chars }
      expect(transitions_chars).to include('a', 'b')
    end

    it 'converts concatination NFA to DFA' do
      # NFAを構築: パターン 'ab'
      node = Hoozmo::Node::Concatenation.new([
                                               Hoozmo::Node::Literal.new('a'),
                                               Hoozmo::Node::Literal.new('b')
                                             ])
      state = Hoozmo::Automaton::StateID.new(0)
      nfa = Hoozmo::Automaton::NFA.new_from_node(node, state)

      # DFAに変換
      dfa = described_class.from_nfa(nfa)

      expect(dfa.start).to be_an(Integer)
      expect(dfa.accept).not_to be_empty
    end
  end

  describe 'match?' do
    it 'matches using DFA' do
      # NFAを構築してDFAに変換
      node = Hoozmo::Node::Literal.new('a')
      state = Hoozmo::Automaton::StateID.new(0)
      nfa = Hoozmo::Automaton::NFA.new_from_node(node, state)
      dfa = described_class.from_nfa(nfa)

      expect(dfa.match?('a')).to be true
      expect(dfa.match?('b')).to be false
    end

    it 'matches choice pattern using DFA' do
      node = Hoozmo::Node::Choice.new([
                                        Hoozmo::Node::Literal.new('a'),
                                        Hoozmo::Node::Literal.new('b')
                                      ])
      state = Hoozmo::Automaton::StateID.new(0)
      nfa = Hoozmo::Automaton::NFA.new_from_node(node, state)
      dfa = described_class.from_nfa(nfa)

      expect(dfa.match?('a')).to be true
      expect(dfa.match?('b')).to be true
      expect(dfa.match?('c')).to be false
    end

    it 'matches concatenation pattern using DFA' do
      node = Hoozmo::Node::Concatenation.new([
                                               Hoozmo::Node::Literal.new('a'),
                                               Hoozmo::Node::Literal.new('b')
                                             ])
      state = Hoozmo::Automaton::StateID.new(0)
      nfa = Hoozmo::Automaton::NFA.new_from_node(node, state)
      dfa = described_class.from_nfa(nfa)

      expect(dfa.match?('ab')).to be true
      expect(dfa.match?('a')).to be false
      expect(dfa.match?('b')).to be false
    end
  end
end
