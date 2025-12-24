# frozen_string_literal: true

class Hoozmo
  module Node
    class Concatenation
      attr_reader :children

      def initialize(children)
        @children = children
      end
    end
  end
end
