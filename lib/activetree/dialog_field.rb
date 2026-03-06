# frozen_string_literal: true

module ActiveTree
  class DialogField
    attr_reader :name, :label
    attr_accessor :value, :cursor_pos

    def initialize(name:, label:, value: "")
      @name = name
      @label = label
      @value = value
      @cursor_pos = value.length
    end

    def insert(char)
      @value = "#{value[0...cursor_pos]}#{char}#{value[cursor_pos..]}"
      @cursor_pos += 1
    end

    def backspace
      return if cursor_pos.zero?

      @value = "#{value[0...(cursor_pos - 1)]}#{value[cursor_pos..]}"
      @cursor_pos -= 1
    end

    def cursor_left
      @cursor_pos = [cursor_pos - 1, 0].max
    end

    def cursor_right
      @cursor_pos = [cursor_pos + 1, value.length].min
    end
  end
end
