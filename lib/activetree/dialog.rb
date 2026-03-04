# frozen_string_literal: true

module ActiveTree
  class Dialog
    attr_reader :fields, :focused_field_index, :title
    attr_accessor :error_message

    def initialize(title:, fields:)
      @title = title
      @fields = fields
      @focused_field_index = 0
      @error_message = nil
      @submitted = false
      @cancelled = false
    end

    def focused_field
      fields[focused_field_index]
    end

    def next_field
      @focused_field_index = (focused_field_index + 1) % fields.size
    end

    def insert_char(char)
      focused_field.insert(char)
    end

    def backspace
      focused_field.backspace
    end

    def cursor_left
      focused_field.cursor_left
    end

    def cursor_right
      focused_field.cursor_right
    end

    def submit!
      @submitted = true
    end

    def cancel!
      @cancelled = true
    end

    def submitted?
      @submitted
    end

    def cancelled?
      @cancelled
    end

    def resolved?
      submitted? || cancelled?
    end
  end
end
