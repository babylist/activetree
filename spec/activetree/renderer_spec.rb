# frozen_string_literal: true

require "active_support/concern"
require "tty-screen"
require "tty-box"
require "pastel"

RSpec.describe ActiveTree::Renderer do
  let(:record) do
    obj = double("Record", id: 42, class: double(name: "User"))
    allow(obj).to receive(:respond_to?).with(:tree_node_label).and_return(false)
    allow(obj).to receive(:respond_to?).with(:tree_node_fields).and_return(false)
    allow(obj).to receive(:respond_to?).with(:tree_node_children).and_return(false)
    obj
  end

  let(:state) { ActiveTree::TreeState.new(root_record: record) }
  let(:renderer) { described_class.new(state) }

  before do
    allow(TTY::Screen).to receive(:width).and_return(80)
    allow(TTY::Screen).to receive(:height).and_return(24)
  end

  describe "#render" do
    let(:output) { renderer.render }

    it "includes the header with ActiveTree" do
      expect(output).to include("ActiveTree")
    end

    it "includes the version" do
      expect(output).to include(ActiveTree::VERSION)
    end

    it "includes the root node label" do
      expect(output).to include("User #42")
    end

    it "includes the help bar" do
      expect(output).to include("navigate")
      expect(output).to include("quit")
    end

    it "includes selected record info in detail pane header" do
      expect(output).to include("[User] User #42")
    end

    it "starts with cursor home escape sequence" do
      expect(output).to start_with("\e[H")
    end
  end
end
