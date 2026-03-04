# frozen_string_literal: true

module ActiveTree
  module CharReader
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
