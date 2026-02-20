# frozen_string_literal: true

require "tty-screen"
require "pastel"

module ActiveTree
  class Renderer
    TREE_WIDTH_RATIO = 0.4
    MIN_TREE_WIDTH = 25
    CHROME_LINES = 5 # top border + header + pane title + pane bottom + footer + bottom border

    def initialize(tree_state)
      @state = tree_state
      @pastel = Pastel.new
    end

    def render
      compute_layout
      @state.visible_height = @content_h
      +"\e[H" << render_frame
    end

    private

    def compute_layout
      @width = TTY::Screen.width
      @inner = @width - 2
      @tree_w = [(@width * TREE_WIDTH_RATIO).to_i, MIN_TREE_WIDTH].max
      @detail_w = @inner - @tree_w
      @content_h = TTY::Screen.height - CHROME_LINES - 3
    end

    def render_frame
      tree_lines = render_tree_lines(@tree_w - 1, @content_h)
      detail_lines = render_detail_lines(@detail_w, @content_h)

      top_border +
        pane_title_border +
        pane_content_rows(tree_lines, detail_lines) +
        pane_bottom_border + footer_row + bottom_border
    end

    def top_border
      border = "\u2500" * @inner

      insert!(border, "#{app_name} - ActiveTree v#{ActiveTree::VERSION}")
      "\u250c#{border}\u2510\n"
    end

    def pane_title_border
      tree_border = "\u2500" * (@tree_w - 1)
      detail_border = "\u2500" * @detail_w

      insert!(tree_border, "Tree", at: 1)
      insert!(detail_border, @state.selected_record_node&.label || "Details", at: 1)
      "\u251c#{tree_border}\u252c#{detail_border}\u2524\n"
    end

    def pane_content_rows(tree_lines, detail_lines)
      rows = +""
      @content_h.times do |i|
        tree_cell = ansi_ljust(tree_lines[i] || "", @tree_w - 1)
        detail_cell = ansi_ljust(detail_lines[i] || "", @detail_w)
        rows << "\u2502#{tree_cell}\u2502#{detail_cell}\u2502\n"
      end
      rows
    end

    def pane_bottom_border
      "\u251c#{"\u2500" * (@tree_w - 1)}\u2534#{"\u2500" * @detail_w}\u2524\n"
    end

    def render_tree_lines(width, height)
      visible = @state.visible_nodes
      start_idx = @state.scroll_offset
      end_idx = [start_idx + height, visible.size].min

      (start_idx...end_idx).map do |i|
        node = visible[i]
        line = format_tree_node(node, width)

        # inverse if highlighted in tree
        line = @pastel.inverse(line) if i == @state.cursor_index

        # cyan if not a record
        line = @pastel.cyan(line) unless node.record?

        # bold if selected (details visible)
        line = @pastel.bold(line) if node == @state.selected_record_node

        line
      end
    end

    def format_tree_node(node, width)
      indent = "  " * node.depth
      icon = node.expandable? ? expand_icon(node) : "  "
      truncate("#{indent}#{icon}#{node.label}", width).ljust(width)
    end

    def expand_icon(node)
      node.expanded ? "\u25bc " : "\u25b6 "
    end

    def render_detail_lines(width, height)
      selected = @state.selected_record_node
      return [] unless selected.respond_to?(:detail_pairs)

      selected.detail_pairs.map do |field, value|
        field_str = @pastel.bold(field.to_s.ljust(15))
        " #{field_str} #{truncate(value.to_s, width - 18)}"
      end.first(height)
    end

    def footer_row
      help = " \u2191\u2193 navigate  Space expand/collapse  Enter select  q quit "
      "\u2502#{@pastel.inverse(help.center(@inner))}\u2502\n"
    end

    def bottom_border
      "\u2514#{"\u2500" * @inner}\u2518\n"
    end

    def ansi_ljust(str, width)
      visible = str.gsub(/\e\[[0-9;]*m/, "").length
      padding = [width - visible, 0].max
      "#{str}#{" " * padding}"
    end

    def truncate(str, max_length)
      return str if str.length <= max_length

      "#{str[0...(max_length - 1)]}\u2026"
    end

    def app_name
      Rails.application.class.module_parent_name
    rescue StandardError => e
      "Rails App"
    end

    def insert!(original, to_insert, at: 1)
      original[at, to_insert.length] = to_insert
    end
  end
end
