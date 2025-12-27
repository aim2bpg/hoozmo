# frozen_string_literal: true

class Hoozmo
  class Parser
    def initialize(pattern)
      @pattern = pattern
      @offset = 0
    end

    def parse
      ast = parse_choice

      raise 'Unexpected end of pattern' unless eol?

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

      children << parse_literal until stop_parsing_concatenation?

      return children.first if children.length == 1
      return Node::Epsilon.new if children.empty?

      Node::Concatenation.new(children)
    end

    def stop_parsing_concatenation?
      eol? || current == '|'
    end

    def parse_literal
      raise 'Unexpected end of pattern' if eol?

      char = current
      case char
      when '|'
        raise "Unexpected character: #{char}"
      else
        next_char
        Node::Literal.new(char)
      end
    end
  end
end
