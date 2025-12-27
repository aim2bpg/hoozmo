# frozen_string_literal: true

class Hoozmo
  module Node
    class Literal
      attr_reader :value

      def initialize(value)
        @value = value
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
end
