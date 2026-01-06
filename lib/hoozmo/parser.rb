# frozen_string_literal: true

class Hoozmo
  class Parser
    def initialize(pattern)
      @pattern = pattern
      @offset = 0
    end

    def parse
      ast = parse_choice

      raise "Unexpected character #{current} at position #{@offset}" unless eol? # 解析終了後に未処理の文字があればエラー

      ast
    end

    private

    def current
      @pattern[@offset]
    end

    def eol?
      @offset >= @pattern.length
    end

    def next_char
      @offset += 1
    end

    def parse_choice
      children = []
      children << parse_concatenation

      while current == '|'
        next_char
        children << parse_concatenation
      end

      return children.first if children.length == 1

      Node::Choice.new(children)
    end

    def parse_concatenation
      children = []

      until stop_parsing_concatenation?
        children << parse_group # parse_literal から parse_group に変更
      end

      return children.first if children.length == 1
      return Node::Epsilon.new if children.empty?

      Node::Concatenation.new(children)
    end

    def stop_parsing_concatenation?
      eol? || current == '|' || current == ')'
    end

    def parse_literal
      raise 'Unexpected end of pattern' if eol?

      char = current
      case char
      when '(', ')', '|', '*', '+', '?' # これらはリテラルではない
        raise "Unexpected character: #{char} at position #{@offset}"
      else
        next_char
        Node::Literal.new(char)
      end
    end

    def parse_group
      return parse_literal if current != '('

      # 開き括弧の位置を記録（エラーメッセージ用）
      paren_pos = @offset
      next_char # '(' をスキップ

      # 括弧内を再帰的にパース
      child = parse_choice

      # 閉じ括弧のチェック
      if current != ')'
        raise "Expected closing parenthesis for '(' at position #{paren_pos}. " \
              "Got: #{current || 'end of pattern'}"
      end

      next_char # ')' をスキップ
      child
    end
  end
end
