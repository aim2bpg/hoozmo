# frozen_string_literal: true

class Hoozmo
  class Parser
    def initialize(pattern)
      @pattern = pattern
      @offset = 0
    end

    def parse
      children = []

      # 文字列を最後まで読む
      until eol?
        char = current
        children << Node::Literal.new(char)
        next_char
      end

      # 子ノードが1つだけならそれを返す
      return children.first if children.length == 1

      # 複数あればConcatenationで包む
      Node::Concatenation.new(children)
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
  end
end
