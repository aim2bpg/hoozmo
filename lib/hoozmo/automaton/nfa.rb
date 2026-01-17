# frozen_string_literal: true

# require 'sorted_set'  # wasm環境でエラーとなるため、Setで代用

class Hoozmo
  module Automaton
    class NFA
      attr_accessor :start, :accept, :transitions

      def initialize(start, accept)
        @start = start          # StateID: 初期状態
        @accept = accept        # Array of StateID: 受理状態の配列
        @transitions = Set.new  # Set of [from, label, to]
      end

      def add_transition(from, char, to)
        @transitions << [from, char, to]
      end

      def add_epsilon_transition(from, to)
        @transitions << [from, nil, to]
      end

      def self.new_from_node(node, state)
        raise ArgumentError, 'Node cannot be nil' if node.nil?

        case node
        when Node::Literal
          build_literal(node, state)
        when Node::Epsilon
          build_epsilon(state)
        when Node::Concatenation
          build_concatenation(node, state)
        when Node::Choice
          build_choice(node, state)
        when Node::Repetition
          if node.zero_or_more?
            build_zero_or_more(node.child, state)
            # elsif node.one_or_more?  # 次章で実装
            # elsif node.optional?     # 次章で実装
          end
        else
          raise ArgumentError, "Unsupported node type: #{node.class}"
        end
      end

      def match?(input)
        # 初期状態のε 閉包から始まる
        current_states = epsilon_closure(Set[@start])

        input.each_char do |char|
          # 次の状態集合を計算
          next_states = Set.new

          # 現在のすべての状態から遷移を試す
          current_states.each do |state|
            @transitions.each do |from, label, to|
              next_states << to if from == state && label == char && from == state && label == char
            end
          end

          # 遷移できなければ失敗
          return false if next_states.empty?

          # 次の状態集合のε 閉包を計算
          current_states = epsilon_closure(next_states)
        end

        # 最終的な状態集合に受理状態が含まれるか
        current_states.any? { |state| @accept.include?(state) }
      end

      def self.build_literal(node, state)
        start_state = state.new_state
        accept_state = state.new_state

        nfa = new(start_state, [accept_state])
        nfa.add_transition(start_state, node.value, accept_state)
        nfa
      end

      def self.build_epsilon(state)
        start_state = state.new_state
        accept_state = state.new_state

        nfa = new(start_state, [accept_state])
        nfa.add_epsilon_transition(start_state, accept_state)
        nfa
      end

      def self.build_concatenation(node, state)
        # 各子ノードのNFAを構築
        nfas = node.children.map { |child| new_from_node(child, state) }

        # 最初のNFAから始める
        nfa = nfas.first

        # 残りのNFAを順番に連結
        nfas.drop(1).each do |next_nfa|
          # 遷移のマージ
          nfa.transitions.merge(next_nfa.transitions)

          # 現在のacceptから次のstartへε遷移
          nfa.accept.each do |accept_state|
            nfa.add_epsilon_transition(accept_state, next_nfa.start)
          end

          # acceptを更新
          nfa.accept = next_nfa.accept
        end

        nfa
      end

      def self.build_choice(node, state)
        # 各選択肢のNFAを構築
        nfas = node.children.map { |child| new_from_node(child, state) }

        # 新しい開始状態
        start_state = state.new_state

        # accept状態は各NFAのaccept状態の和集合
        accepts = nfas.flat_map(&:accept)

        nfa = new(start_state, accepts)

        # 各選択肢のNFAを統合
        nfas.each do |child_nfa|
          nfa.transitions.merge(child_nfa.transitions)
          # 新しい開始状態から各選択肢の開始状態へのε 遷移を追加
          nfa.add_epsilon_transition(start_state, child_nfa.start)
        end

        nfa
      end

      def epsilon_closure(start)
        visited = Set.new
        to_visit = []

        start.each do |state|
          to_visit << state unless visited.include?(state)
        end

        until to_visit.empty?
          state = to_visit.shift
          next if visited.include?(state)

          visited << state

          @transitions.each do |from, label, to|
            to_visit << to if from == state && label.nil? && !visited.include?(to)
          end
        end

        # ::SortedSet.new(visited) # 状態集合の比較のためにSortedSetで返す(wasm環境でエラーとなるため、Setで代用)
        visited # 状態集合の比較のためにSetで返す
      end

      def self.build_zero_or_more(child_node, state)
        # 子ノードのNFAを構築
        child_nfa = new_from_node(child_node, state)

        # 新しい開始状態と受理状態
        start_state = state.new_state
        accept_state = state.new_state

        nfa = new(start_state, [accept_state])

        # 子NFAの遷移をマージ
        nfa.transitions.merge(child_nfa.transitions)

        # 新しい開始状態から子NFAの開始へ（1回目の実行）
        nfa.add_epsilon_transition(start_state, child_nfa.start)

        # 新しい開始状態から受理状態へ（0回の繰り返し）
        nfa.add_epsilon_transition(start_state, accept_state)

        # 子NFAの各受理状態から:
        child_nfa.accept.each do |child_accept|
          # 新しい受理状態へ（終了）
          nfa.add_epsilon_transition(child_accept, accept_state)

          # 子NFAの開始へ戻る（ループバック）
          nfa.add_epsilon_transition(child_accept, child_nfa.start)
        end

        nfa
      end
    end
  end
end
