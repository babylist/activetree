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
      border_style = @state.tree_focused? ? { fg: :magenta } : { fg: :bright_black }
      TTY::Box.frame(
        top: 2,
        left: 0,
        width: @tree_w,
        height: @content_h + 2,
        border: :light,
        style: { border: border_style }
      ) { lines.join("\n") }
    end

    def build_detail_box(lines)
      detail_title = "[#{@state.selected_record_node&.class_label}] #{@state.selected_record_node&.label}"
      border_style = @state.detail_focused? ? { fg: :magenta } : { fg: :bright_black }
      TTY::Box.frame(
        top: 2,
        left: @tree_w,
        width: @detail_w,
        height: @content_h + 2,
        border: :light,
        style: { border: border_style },
        title: { top_left: " #{detail_title} " }
      ) { lines.join("\n") }
    end

    def positioned_footer
      help = " \u2191\u2193 navigate  Tab switch pane  Space expand  Enter select  r root  q quit "
      "\e[#{@content_h + 5};1H#{@pastel.magenta.inverse(help.center(@width))}"
    end

    def render_tree_lines(width, height)
      visible = @state.visible_nodes
      total = visible.size
      needs_scrollbar = total > height
      node_width = needs_scrollbar ? width - 1 : width
      start_idx = @state.scroll_offset
      end_idx = [start_idx + height, total].min

      lines = (start_idx...end_idx).map do |i|
        node = visible[i]
        line = format_tree_node(node, node_width)

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

      return lines unless needs_scrollbar

      append_scrollbar(lines, width, height, total, @state.scroll_offset, active: @state.tree_focused?)
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
      unless selected.respond_to?(:detail_pairs)
        @state.detail_content_height = 0
        return []
      end

      all_lines = selected.detail_pairs.map { |field, value| format_detail_field(field, value, width) }
      @state.detail_content_height = all_lines.size

      start_idx = @state.detail_scroll_offset
      end_idx = [start_idx + height, all_lines.size].min
      visible_lines = all_lines[start_idx...end_idx]

      return visible_lines unless all_lines.size > height

      append_scrollbar(visible_lines, width, height, all_lines.size, @state.detail_scroll_offset,
                       active: @state.detail_focused?)
    end

    def format_detail_field(field, value, width)
      field_str = @pastel.bold(field.to_s.ljust(15))
      value_str = case value
                  when true, false
                    value ? @pastel.green("\u2713") : @pastel.red("\u2717")
                  else
                    truncate(value.to_s, width - 18)
                  end
      " #{field_str} #{value_str}"
    end

    def append_scrollbar(lines, width, height, total, offset, active:)
      thumb_size = [(height.to_f / total * height).ceil, 1].max
      max_offset = [total - height, 1].max
      max_thumb_pos = height - thumb_size
      thumb_start = (offset.to_f / max_offset * max_thumb_pos).round

      if max_thumb_pos >= 2 && offset.positive? && offset < max_offset
        thumb_start = thumb_start.clamp(1, max_thumb_pos - 1)
      end

      lines.each_with_index.map do |line, i|
        visible_width = Strings::ANSI.sanitize(line).length
        padding = width - visible_width
        padded = padding > 1 ? "#{line}#{" " * (padding - 1)}" : line

        in_thumb = i >= thumb_start && i < thumb_start + thumb_size
        char = in_thumb ? "\u2588" : "\u2591"
        styled_char = in_thumb && active ? @pastel.magenta(char) : @pastel.dim(char)
        "#{padded}#{styled_char}"
      end
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
