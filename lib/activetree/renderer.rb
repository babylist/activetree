# frozen_string_literal: true

require "tty-screen"
require "tty-box"
require "pastel"

module ActiveTree
  class Renderer
    TREE_WIDTH_RATIO = 0.4
    MIN_TREE_WIDTH = 25
    CHROME_LINES = 5 # 2 header + 2 box borders + 1 footer

    def initialize(tree_state)
      @state = tree_state
      @pastel = Pastel.new
    end

    def render
      compute_layout
      @state.visible_height = @content_h
      +"\e[H\e[J" << render_frame
    end

    private

    def compute_layout
      @width = TTY::Screen.width
      @tree_w = [(@width * TREE_WIDTH_RATIO).to_i, MIN_TREE_WIDTH].max
      @detail_w = @width - @tree_w
      @content_h = TTY::Screen.height - CHROME_LINES
    end

    def render_frame
      tree_content = render_tree_lines(@tree_w - 2, @content_h)
      detail_content = render_detail_lines(@detail_w - 2, @content_h)

      top_border +
        build_tree_box(tree_content) +
        build_detail_box(detail_content) +
        positioned_footer
    end

    def top_border
      @pastel.magenta.bold("ActiveTree v#{ActiveTree::VERSION}\n") + @pastel.dim("#{app_name}\n")
    end

    def build_tree_box(lines)
      TTY::Box.frame(
        top: 2,
        left: 0,
        width: @tree_w,
        height: @content_h + 2,
        border: :light
      ) { lines.join("\n") }
    end

    def build_detail_box(lines)
      detail_title = "[#{@state.selected_record_node&.class_label}] #{@state.selected_record_node&.label}"
      TTY::Box.frame(
        top: 2,
        left: @tree_w,
        width: @detail_w,
        height: @content_h + 2,
        border: :light,
        title: { top_left: " #{detail_title} " }
      ) { lines.join("\n") }
    end

    def positioned_footer
      help = " \u2191\u2193 navigate  Space expand/collapse  Enter select  r Make selected root  q quit "
      "\e[#{@content_h + 5};1H#{@pastel.magenta.inverse(help.center(@width))}"
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

        # italic if it is the root node
        line = @pastel.italic(line) if node.record? && node.record == @state.root.record

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

        value_str = case value
                    when true, false
                      value ? @pastel.green("✓") : @pastel.red("✗")
                    else
                      truncate(value.to_s, width - 18)
                    end

        " #{field_str} #{value_str}"
      end.first(height)
    end

    def truncate(str, max_length)
      return str if str.length <= max_length

      "#{str[0...(max_length - 1)]}\u2026"
    end

    def app_name
      "#{Rails.application.class.module_parent_name} (#{Rails.env})"
    rescue StandardError
      "Rails App"
    end
  end
end
