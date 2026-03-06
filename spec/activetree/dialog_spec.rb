# frozen_string_literal: true

RSpec.describe ActiveTree::Dialog do
  let(:fields) do
    [
      ActiveTree::DialogField.new(name: :model, label: "Model", value: "User"),
      ActiveTree::DialogField.new(name: :query, label: "Query", value: "")
    ]
  end

  subject(:dialog) { described_class.new(title: "Test", fields: fields) }

  describe "initial state" do
    it "is not submitted" do
      expect(dialog.submitted?).to be false
    end

    it "is not cancelled" do
      expect(dialog.cancelled?).to be false
    end

    it "is not resolved" do
      expect(dialog.resolved?).to be false
    end

    it "has nil error_message" do
      expect(dialog.error_message).to be_nil
    end
  end

  describe "#focused_field" do
    it "returns the field at focused_field_index" do
      expect(dialog.focused_field).to eq(fields[0])
    end
  end

  describe "#next_field" do
    it "cycles through fields" do
      dialog.next_field
      expect(dialog.focused_field).to eq(fields[1])
    end

    it "wraps around" do
      dialog.next_field
      dialog.next_field
      expect(dialog.focused_field).to eq(fields[0])
    end
  end

  describe "#insert_char" do
    it "delegates to focused field" do
      dialog.insert_char("X")
      expect(fields[0].value).to eq("UserX")
    end
  end

  describe "#backspace" do
    it "delegates to focused field" do
      dialog.backspace
      expect(fields[0].value).to eq("Use")
    end
  end

  describe "#cursor_left" do
    it "delegates to focused field" do
      expect { dialog.cursor_left }.to change { fields[0].cursor_pos }.by(-1)
    end
  end

  describe "#cursor_right" do
    it "delegates to focused field" do
      fields[0].cursor_pos = 0
      expect { dialog.cursor_right }.to change { fields[0].cursor_pos }.by(1)
    end
  end

  describe "#submit!" do
    it "sets submitted and resolved" do
      dialog.submit!
      expect(dialog.submitted?).to be true
      expect(dialog.resolved?).to be true
    end
  end

  describe "#cancel!" do
    it "sets cancelled and resolved" do
      dialog.cancel!
      expect(dialog.cancelled?).to be true
      expect(dialog.resolved?).to be true
    end
  end

  describe "#error_message" do
    it "is readable and writable" do
      dialog.error_message = "something went wrong"
      expect(dialog.error_message).to eq("something went wrong")
    end
  end
end
