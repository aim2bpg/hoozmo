# frozen_string_literal: true

class Hoozmo
  module Automaton
    class StateID
      attr_reader :id

      def initialize(id)
        @id = id
      end

      def new_state
        @id += 1
        StateID.new(@id)
      end

      def <=>(other)
        return nil unless other.is_a?(StateID)

        @id <=> other.id
      end

      def hash
        @id.hash
      end

      def eql?(other)
        other.is_a?(StateID) && @id == other.id
      end
    end
  end
end
