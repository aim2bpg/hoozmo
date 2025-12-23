# frozen_string_literal: true

class Hoozmo
  def initialize(pattern)
    @pattern = pattern
  end

  def match?(input)
    @pattern == input
  end
end
