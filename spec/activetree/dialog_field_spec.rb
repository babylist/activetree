# frozen_string_literal: true

RSpec.describe ActiveTree::DialogField do
  subject(:field) { described_class.new(name: :query, label: "Query", value: "hello") }

  describe "#initialize" do
    it "sets cursor_pos to end of initial value" do
      expect(field.cursor_pos).to eq(5)
    end

    it "defaults value to empty string" do
      empty = described_class.new(name: :q, label: "Q")
      expect(empty.value).to eq("")
      expect(empty.cursor_pos).to eq(0)
    end
  end

  describe "#insert" do
    it "inserts at cursor position and advances cursor" do
      field.insert("!")
      expect(field.value).to eq("hello!")
      expect(field.cursor_pos).to eq(6)
    end

    it "splices correctly when cursor is in the middle" do
      field.cursor_pos = 2
      field.insert("X")
      expect(field.value).to eq("heXllo")
      expect(field.cursor_pos).to eq(3)
    end
  end

  describe "#backspace" do
    it "removes char before cursor and decrements cursor" do
      field.backspace
      expect(field.value).to eq("hell")
      expect(field.cursor_pos).to eq(4)
    end

    it "is a no-op at position 0" do
      field.cursor_pos = 0
      field.backspace
      expect(field.value).to eq("hello")
      expect(field.cursor_pos).to eq(0)
    end
  end

  describe "#cursor_left" do
    it "decrements cursor position" do
      field.cursor_left
      expect(field.cursor_pos).to eq(4)
    end

    it "clamps at 0" do
      field.cursor_pos = 0
      field.cursor_left
      expect(field.cursor_pos).to eq(0)
    end
  end

  describe "#cursor_right" do
    it "increments cursor position" do
      field.cursor_pos = 3
      field.cursor_right
      expect(field.cursor_pos).to eq(4)
    end

    it "clamps at value length" do
      field.cursor_right
      expect(field.cursor_pos).to eq(5)
    end
  end
end
