# frozen_string_literal: true

module ActiveTree
  class TreeState
    attr_reader :root, :cursor_index, :scroll_offset, :selected_record_node
    attr_accessor :visible_height

    def initialize(root_record:)
      @root = RecordNode.new(record: root_record)
      @root.expanded = true
      @cursor_index = 0
      @scroll_offset = 0
      @visible_height = 20
      @selected_record_node = @root
    end

    def visible_nodes
      root.visible_nodes
    end

    def cursor_node
      visible_nodes[cursor_index]
    end

    def move_up
      @cursor_index = [cursor_index - 1, 0].max
      adjust_scroll
    end

    def move_down
      @cursor_index = [cursor_index + 1, visible_nodes.size - 1].min
      adjust_scroll
    end

    def toggle_expand
      node = cursor_node
      return unless node

      if node.is_a?(LoadMoreNode)
        node.activate!
      elsif node.expandable?
        node.expanded = !node.expanded
        clamp_cursor
      end
    end

    def select_current
      node = cursor_node
      @selected_record_node = node if node.is_a?(RecordNode)
    end

    private

    def adjust_scroll
      if cursor_index < scroll_offset
        @scroll_offset = cursor_index
      elsif cursor_index >= scroll_offset + visible_height
        @scroll_offset = cursor_index - visible_height + 1
      end
    end

    def clamp_cursor
      max = visible_nodes.size - 1
      @cursor_index = [cursor_index, max].min
    end
  end
end
