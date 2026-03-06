# frozen_string_literal: true

require "stringio"

RSpec.describe ActiveTree::DialogInputHandler do
  def handler_for(chars)
    io = StringIO.new(chars)
    # Fake raw mode: StringIO doesn't support raw, so we define it
    def io.raw(**)
      yield self
    end
    described_class.new(input: io)
  end

  describe "#read_action" do
    it "returns :submit for \\r" do
      expect(handler_for("\r").read_action).to eq(:submit)
    end

    it "returns :cancel for bare \\e" do
      expect(handler_for("\e").read_action).to eq(:cancel)
    end

    it "returns :next_field for \\t" do
      expect(handler_for("\t").read_action).to eq(:next_field)
    end

    it "returns :backspace for \\x7f" do
      expect(handler_for("\x7f").read_action).to eq(:backspace)
    end

    it "returns :cursor_right for \\e[C" do
      expect(handler_for("\e[C").read_action).to eq(:cursor_right)
    end

    it "returns :cursor_left for \\e[D" do
      expect(handler_for("\e[D").read_action).to eq(:cursor_left)
    end

    it "returns nil for arrow up \\e[A" do
      expect(handler_for("\e[A").read_action).to be_nil
    end

    it "returns nil for arrow down \\e[B" do
      expect(handler_for("\e[B").read_action).to be_nil
    end

    it "returns [:insert, char] for printable characters" do
      expect(handler_for("a").read_action).to eq([:insert, "a"])
      expect(handler_for("Z").read_action).to eq([:insert, "Z"])
      expect(handler_for(" ").read_action).to eq([:insert, " "])
    end
  end
end
