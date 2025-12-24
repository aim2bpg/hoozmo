# frozen_string_literal: true

require_relative 'hoozmo/node'
require_relative 'hoozmo/parser'

class Hoozmo
  def initialize(pattern)
    @pattern = pattern
    @ast = Parser.new(pattern).parse
  end

  def match?(input)
    result = match_node(@ast, input, 0)
    # マッチング成功 かつ 入力を全て消費した
    result && result == input.length
  end

  private

  def match_node(node, input, pos)
    case node
    when Node::Literal
      match_literal(node, input, pos)
    when Node::Concatenation
      match_concatenation(node, input, pos)
    else
      false
    end
  end

  def match_literal(node, input, pos)
    # 入力の終端を超えている
    return false if pos >= input.length

    # 文字が一致しない
    return false if input[pos] != node.value

    # マッチ成功、次の位置を返す
    pos + 1
  end

  def match_concatenation(node, input, pos)
    # 各子ノードを順番にマッチ
    node.children.each do |child|
      result = match_node(child, input, pos)
      return false unless result

      pos = result
    end

    # すべての子ノードがマッチ、最終位置を返す
    pos
  end
end
