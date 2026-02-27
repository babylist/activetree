# frozen_string_literal: true

module ActiveTree
  class TreeState
    attr_reader :root, :cursor_index, :scroll_offset, :selected_record_node,
                :focused_pane, :detail_scroll_offset
    attr_accessor :visible_height, :detail_content_height

    def initialize(root_record:)
      @root = RecordNode.new(record: root_record, tree_state: self)
      @root.expanded = true
      @cursor_index = 0
      @scroll_offset = 0
      @visible_height = 20
      @selected_record_node = @root
      @focused_pane = :tree
      @detail_scroll_offset = 0
      @detail_content_height = 0
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

    def toggle_focus
      @focused_pane = @focused_pane == :tree ? :detail : :tree
    end

    def detail_focused?
      @focused_pane == :detail
    end

    def tree_focused?
      @focused_pane == :tree
    end

    def scroll_detail_up
      @detail_scroll_offset = [@detail_scroll_offset - 1, 0].max
    end

    def scroll_detail_down
      max_offset = [@detail_content_height - visible_height, 0].max
      @detail_scroll_offset = [@detail_scroll_offset + 1, max_offset].min
    end

    def select_current
      node = cursor_node
      return unless node.is_a?(RecordNode)

      @selected_record_node = node
      @detail_scroll_offset = 0
    end

    def make_selected_record_root
      node = selected_record_node
      return unless node.is_a?(RecordNode)

      @root = RecordNode.new(record: node.record, tree_state: self)
      @root.expanded = true
      @selected_record_node = @root
      @cursor_index = 0
      @scroll_offset = 0
      @detail_scroll_offset = 0
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
