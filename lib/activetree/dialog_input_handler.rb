# frozen_string_literal: true

module ActiveTree
  class DialogInputHandler
    include CharReader

    def initialize(input: $stdin)
      @input = input
    end

    def read_action
      char = read_char
      return nil unless char

      case char
      when "\e"
        :cancel
      when "\r"
        :submit
      when "\t"
        :next_field
      when "\x7f", "\b"
        :backspace
      when "\e[D"
        :cursor_left
      when "\e[C"
        :cursor_right
      when "\e[A", "\e[B"
        nil
      else
        printable?(char) ? [:insert, char] : nil
      end
    end

    private

    def printable?(char)
      char.length == 1 && char.ord >= 32 && char.ord < 127
    end
  end
end
