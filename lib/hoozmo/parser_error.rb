# frozen_string_literal: true

class Hoozmo
  class ParserError < StandardError
    attr_reader :position, :pattern

    def initialize(message, position, pattern)
      @position = position
      @pattern = pattern

      super(build_message(message))
    end

    private

    def build_message(message)
      lines = []
      lines << message
      lines << ''
      lines << "pattern: #{@pattern}"
      lines << "#{' ' * (9 + @position)}^"
      lines << "position: #{@position}"
      lines.join("\n")
    end
  end
end
