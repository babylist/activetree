# frozen_string_literal: true

module ActiveTree
  class TreeNode
    attr_accessor :depth, :parent, :expanded, :tree_state

    def initialize(tree_state: nil, depth: 0, parent: nil)
      @depth = depth
      @parent = parent
      @expanded = false
      @tree_state = tree_state
    end

    def expandable?
      raise "#{self.class}#expandable? not implemented"
    end

    def children
      raise "#{self.class}#children not implemented"
    end

    def label
      raise "#{self.class}#label not implemented"
    end

    def record?
      false
    end

    def loaded?
      false
    end

    def reset_depth(depth)
      @depth = depth

      # Using ivar directly to avoid eager-loading the entire object graph
      # (@children is only present after explicitly being loaded)
      @children&.each { |child| child.reset_depth(depth + 1) }
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
