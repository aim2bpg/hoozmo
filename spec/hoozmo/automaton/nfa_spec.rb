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

    it 'builds NFA from one-or-more Repetition node' do
      node = Hoozmo::Node::Repetition.new(
        Hoozmo::Node::Literal.new('a'),
        :one_or_more
      )
      state = Hoozmo::Automaton::StateID.new(0)

      nfa = described_class.new_from_node(node, state)

      expect(nfa.start).to be_a(Hoozmo::Automaton::StateID)
      expect(nfa.accept.length).to eq(1)
      # ε 遷移によるループ構造があるはず（*と似ているが、0回の遷移がない）
      epsilon_transitions = nfa.transitions.select { |_, label, _| label.nil? }
      expect(epsilon_transitions.size).to be >= 3
    end

    it 'builds NFA from optional Repetition node' do
      node = Hoozmo::Node::Repetition.new(
        Hoozmo::Node::Literal.new('a'),
        :optional
      )
      state = Hoozmo::Automaton::StateID.new(0)

      nfa = described_class.new_from_node(node, state)

      expect(nfa.start).to be_a(Hoozmo::Automaton::StateID)
      expect(nfa.accept.length).to be >= 1
      # 開始状態が受理状態に含まれるはず（0回の選択肢）
      expect(nfa.accept).to include(nfa.start)
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

    it 'matches one-or-more pattern' do
      node = Hoozmo::Node::Repetition.new(
        Hoozmo::Node::Literal.new('a'),
        :one_or_more
      )
      state = Hoozmo::Automaton::StateID.new(0)
      nfa = described_class.new_from_node(node, state)

      expect(nfa.match?('')).to be false    # 0回はNG
      expect(nfa.match?('a')).to be true    # 1回
      expect(nfa.match?('aaa')).to be true  # 3回
      expect(nfa.match?('b')).to be false   # マッチしない
    end

    it 'matches optional pattern' do
      node = Hoozmo::Node::Repetition.new(
        Hoozmo::Node::Literal.new('a'),
        :optional
      )
      state = Hoozmo::Automaton::StateID.new(0)
      nfa = described_class.new_from_node(node, state)

      expect(nfa.match?('')).to be true     # 0回
      expect(nfa.match?('a')).to be true    # 1回
      expect(nfa.match?('aa')).to be false  # 2回はNG
      expect(nfa.match?('b')).to be false   # マッチしない
    end

    context 'with one-or-more repetition' do
      context 'with pattern a+' do
        let(:regex) { Hoozmo.new('a+') }

        it 'does not match empty string' do
          expect(regex.match?('')).to be false
        end

        it 'matches single character' do
          expect(regex.match?('a')).to be true
        end

        it 'matches multiple characters' do
          expect(regex.match?('aaaa')).to be true
        end
      end
    end

    context 'with pattern (ab)+' do
      let(:regex) { Hoozmo.new('(ab)+') }

      it 'does not match empty string' do
        expect(regex.match?('')).to be false
      end

      it 'matches single repetition' do
        expect(regex.match?('ab')).to be true
      end

      it 'matches multiple repetition' do
        expect(regex.match?('ababab')).to be true
      end
    end

    context 'with optional repetition' do
      context 'with pattern a?' do
        let(:regex) { Hoozmo.new('a?') }

        it 'matches empty string' do
          expect(regex.match?('')).to be true
        end

        it 'matches single character' do
          expect(regex.match?('a')).to be true
        end

        it 'does not match multiple characters' do
          expect(regex.match?('aa')).to be false
        end
      end
    end

    context 'with pattern ab?c' do
      let(:regex) { Hoozmo.new('ab?c') }

      it 'matches without optional part' do
        expect(regex.match?('ac')).to be true
      end

      it 'matches with optional part' do
        expect(regex.match?('abc')).to be true
      end

      it 'does not match with repeated optional part' do
        expect(regex.match?('abbc')).to be false
      end
    end

    context 'with combined quantifiers' do
      let(:regex) { Hoozmo.new('a+b*c?') }

      it 'matches various combinations' do
        expect(regex.match?('a')).to be true
        expect(regex.match?('ab')).to be true
        expect(regex.match?('abc')).to be true
        expect(regex.match?('aabc')).to be true
        expect(regex.match?('aabbc')).to be true
        expect(regex.match?('aaabbbcc')).to be false # cが2つ
      end
    end
  end
end
