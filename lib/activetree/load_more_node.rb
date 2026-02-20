# frozen_string_literal: true

module ActiveTree
  class LoadMoreNode < TreeNode
    attr_reader :group

    def initialize(group:, depth: 0, parent: nil)
      super(depth: depth, parent: parent)
      @group = group
    end

    def label
      "[load more...]"
    end

    def expandable?
      false
    end

    def children
      []
    end

    def activate!
      group.load_more!
    end
  end
end
