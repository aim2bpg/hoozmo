# frozen_string_literal: true

class Hoozmo
  module Node
    class Concatenation
      attr_reader :children

      def initialize(children)
        @children = children
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
    end
  end
end
