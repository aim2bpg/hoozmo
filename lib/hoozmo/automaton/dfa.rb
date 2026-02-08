# frozen_string_literal: true

class Hoozmo
  module Automaton
    class DFA
      attr_accessor :start, :accept, :transitions

      def initialize(start, accept)
        @start = start          # Integer: 初期状態のID
        @accept = accept        # Set: 受理状態のID集合
        @transitions = Set.new  # Set of [from_id, char, to_id]
        @cache = {}             # Hash: 遷移のキャッシュ
      end

      def add_transition(from, char, to)
        @transitions << [from, char, to]
      end

      def self.from_nfa(nfa, *args, **kwargs)
        _use_cache = kwargs.key?(:use_cache) ? kwargs[:use_cache] : (args[0] || false)

        dfa, dfa_states, queue, nfa_accept_set = initialize_from_nfa(nfa)

        # BFSで状態を構築
        while (current_nfa_states = queue.shift)
          current_dfa_id = dfa_states[current_nfa_states]

          # 受理状態の判定
          dfa.accept << current_dfa_id if current_nfa_states.any? { |state| nfa_accept_set.include?(state) }

          # 遷移マップの構築
          transition_map = build_transition_map(nfa, current_nfa_states)

          # 新しい状態の登録と遷移の追加
          transition_map.each do |char, next_nfa_states|
            next_dfa_id = register_state(dfa_states, next_nfa_states, queue)
            dfa.add_transition(current_dfa_id, char, next_dfa_id)
          end
        end

        dfa
      end

      def self.build_transition_map(nfa, current_nfa_states)
        map = Hash.new { |h, k| h[k] = Set.new }

        current_nfa_states.each do |state|
          nfa.transitions.each do |from, label, to|
            next if from != state || label.nil?

            map[label].merge(nfa.epsilon_closure(Set[to]))
          end
        end

        map
      end

      private_class_method :build_transition_map

      def self.register_state(dfa_states, next_nfa_states, queue)
        unless dfa_states.key?(next_nfa_states)
          next_dfa_id = dfa_states.length
          dfa_states[next_nfa_states] = next_dfa_id
          queue << next_nfa_states
        end

        dfa_states[next_nfa_states]
      end

      private_class_method :register_state

      def self.initialize_from_nfa(nfa)
        dfa_states = {}
        queue = []
        nfa_accept_set = nfa.accept.to_set

        # 初期状態
        start_set = Set.new([nfa.start])
        start_states = nfa.epsilon_closure(start_set)
        dfa_states[start_states] = 0
        queue << start_states

        dfa = new(0, Set.new)

        [dfa, dfa_states, queue, nfa_accept_set]
      end

      private_class_method :initialize_from_nfa

      def match?(input, *args, **kwargs)
        use_cache = if kwargs.key?(:use_cache)
                      kwargs[:use_cache]
                    else
                      args[0] || false
                    end

        chars = input.chars

        # 各開始位置から試行
        (0..chars.length).each do |start_pos|
          return true if match_from?(chars, start_pos, use_cache)
        end

        false
      end

      def match_from?(chars, start_pos, use_cache)
        state = @start

        (start_pos...chars.length).each do |i|
          # 各ステップで受理状態かチェック
          return true if @accept.include?(state)

          char = chars[i]
          state = if use_cache && (cached = @cache[[state, char]])
                    cached
                  else
                    next_transition(state, char, use_cache)
                  end

          return false unless state
        end

        # 最後の状態もチェック
        @accept.include?(state)
      end

      def next_transition(current, input, use_cache)
        next_state = @transitions.find do |from, label, _|
          from == current && label == input
        end&.last

        # キャッシュに保存
        @cache[[current, input]] = next_state if use_cache && next_state

        next_state
      end

      private

      attr_accessor :cache
    end
  end
end
