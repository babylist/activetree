# frozen_string_literal: true

module ActiveTree
  class DialogRenderer
    DIALOG_WIDTH = 60
    FIELD_INNER_WIDTH = DIALOG_WIDTH - 6

    def initialize
      @pastel = Pastel.new
    end

    def render(dialog, screen_width, screen_height)
      lines = build_lines(dialog)
      box_height = lines.size + 2
      top = [(screen_height - box_height) / 2, 0].max
      left = [(screen_width - DIALOG_WIDTH) / 2, 0].max

      TTY::Box.frame(
        top: top,
        left: left,
        width: DIALOG_WIDTH,
        height: box_height,
        border: :thick,
        style: { border: { fg: :magenta } },
        title: { top_left: " #{dialog.title} " }
      ) { lines.join("\n") }
    end

    private

    def build_lines(dialog)
      lines = []
      dialog.fields.each_with_index do |field, i|
        focused = i == dialog.focused_field_index
        lines << render_field(field, focused)
        lines << "" if i < dialog.fields.size - 1
      end

      if dialog.error_message
        lines << ""
        lines << @pastel.red(" #{truncate(dialog.error_message, FIELD_INNER_WIDTH)}")
      end

      lines << ""
      lines << @pastel.dim(" Tab: next  Enter: submit  Esc: cancel")
      lines
    end

    def render_field(field, focused)
      label_str = focused ? @pastel.magenta.bold("#{field.label}:") : "#{field.label}:"
      value_display = render_field_value(field, focused)
      " #{label_str} #{value_display}"
    end

    def render_field_value(field, focused)
      max_val_width = FIELD_INNER_WIDTH - field.label.length - 4
      value = field.value

      if focused
        before = value[0...field.cursor_pos]
        cursor_char = field.cursor_pos < value.length ? value[field.cursor_pos] : " "
        after = field.cursor_pos < value.length ? value[(field.cursor_pos + 1)..] : ""
        display = "#{before}#{@pastel.inverse(cursor_char)}#{after}"
        truncate_styled(display, value.length + (cursor_char == " " ? 1 : 0), max_val_width)
      else
        truncate(value, max_val_width)
      end
    end

    def truncate(str, max_length)
      return str if max_length <= 0 || str.length <= max_length

      "#{str[0...(max_length - 1)]}\u2026"
    end

    def truncate_styled(styled_str, plain_length, max_length)
      return styled_str if max_length <= 0 || plain_length <= max_length

      styled_str
    end
  end
end
