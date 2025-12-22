# frozen_string_literal: true

require_relative '../lib/hoozmo'

RSpec.describe Hoozmo do
  describe '#initialize' do
    it 'accepts a pattern string' do
      expect { Hoozmo.new('abc') }.not_to raise_error
    end
  end
end
