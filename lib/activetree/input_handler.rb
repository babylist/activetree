# frozen_string_literal: true

module ActiveTree
  class InputHandler
    KEY_MAP = {
      "\e[A" => :move_up,
      "\e[B" => :move_down,
      " " => :toggle_expand,
      "\r" => :select,
      "q" => :quit,
      "k" => :move_up,
      "j" => :move_down
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
