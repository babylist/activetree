# frozen_string_literal: true

module ActiveTree
  class TreeNode
    attr_accessor :depth, :parent, :expanded

    def initialize(tree_state:, depth: 0, parent: nil)
      @depth = depth
      @parent = parent
      @expanded = false
      @tree_state = tree_state
    end

    def expandable?
      raise NotImplementedError, "#{self.class}#expandable?"
    end

    def children
      raise NotImplementedError, "#{self.class}#children"
    end

    def label
      raise NotImplementedError, "#{self.class}#label"
    end

    def record?
      false
    end

    def visible_nodes
      nodes = [self]
      if expanded && expandable?
        children.each do |child|
          nodes.concat(child.visible_nodes)
        end
      end
      nodes
    end
  end
end
