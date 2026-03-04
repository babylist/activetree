# frozen_string_literal: true

module ActiveTree
  class InputHandler
    include CharReader

    KEY_MAP = {
      "\e[A" => :move_up,
      "k" => :move_up,
      "j" => :move_down,
      "\e[B" => :move_down,
      "\e[C" => :navigate_right,
      "l" => :navigate_right,
      "\e[D" => :navigate_left,
      "h" => :navigate_left,
      " " => :toggle_expand,
      "\r" => :select,
      "q" => :quit,
      "r" => :make_root,
      "\t" => :toggle_focus,
      "f" => :toggle_field_mode,
      "s" => :open_query_dialog
    }.freeze

    def initialize(input: $stdin)
      @input = input
    end

    def read_action
      char = read_char
      return nil unless char

      KEY_MAP[char]
    end
  end
end
