# frozen_string_literal: true

module ActiveTree
  class InputHandler
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
      "f" => :toggle_field_mode
    }.freeze

    def initialize(input: $stdin)
      @input = input
    end

    def read_action
      char = read_char
      return nil unless char

      KEY_MAP[char]
    end

    private

    def read_char
      @input.raw(min: 1) do |io|
        char = io.getc
        return nil unless char
        return read_escape_sequence(char, io) if char == "\e"

        char
      end
    end

    def read_escape_sequence(char, io)
      second = safe_read(io)
      third = safe_read(io)
      return "#{char}#{second}#{third}" if second

      char
    end

    def safe_read(io)
      io.read_nonblock(1)
    rescue StandardError
      nil
    end
  end
end
