# frozen_string_literal: true

require "active_support/concern"

RSpec.describe ActiveTree::TreeState do
  let(:record) do
    obj = double("Record", id: 1, class: double(name: "User"))
    obj
  end

  let(:state) { described_class.new(root_record: record) }

  describe "#initialize" do
    it "creates root as expanded RecordNode" do
      expect(state.root).to be_a(ActiveTree::RecordNode)
      expect(state.root.expanded).to be true
    end

    it "starts cursor at 0" do
      expect(state.cursor_index).to eq(0)
    end

    it "selects root as initial selected node" do
      expect(state.selected_record_node).to eq(state.root)
    end
  end

  describe "#visible_nodes" do
    it "returns at least the root" do
      expect(state.visible_nodes).to include(state.root)
    end
  end

  describe "#cursor_node" do
    it "returns the node at cursor_index" do
      expect(state.cursor_node).to eq(state.root)
    end
  end

  describe "#move_down" do
    it "does not go below the last node" do
      state.move_down
      # With only root visible, cursor should stay at 0
      expect(state.cursor_index).to eq(0)
    end
  end

  describe "#move_up" do
    it "does not go above 0" do
      state.move_up
      expect(state.cursor_index).to eq(0)
    end
  end

  describe "#toggle_expand" do
    context "with an expandable node under cursor" do
      let(:reflection) { Struct.new(:macro).new(:has_many) }

      let(:record_with_children) do
        reflection_ref = reflection
        klass = Class.new do
          define_method(:self_name) { "Order" }

          define_singleton_method(:name) { "Order" }

          define_singleton_method(:reflect_on_association) do |name|
            reflection_ref if name == :items
          end

          define_method(:id) { 1 }

          include ActiveTree::Model
        end
        klass.tree_children :items
        klass.new
      end

      let(:state_with_children) { described_class.new(root_record: record_with_children) }

      it "collapses an expanded node" do
        expect(state_with_children.root.expanded).to be true
        state_with_children.toggle_expand
        expect(state_with_children.root.expanded).to be false
      end

      it "expands a collapsed node" do
        state_with_children.root.expanded = false
        state_with_children.toggle_expand
        expect(state_with_children.root.expanded).to be true
      end
    end
  end

  describe "#select_current" do
    it "sets selected_record_node to cursor node when it is a RecordNode" do
      state.select_current
      expect(state.selected_record_node).to eq(state.root)
    end
  end

  describe "scroll adjustment" do
    it "adjusts scroll when cursor moves beyond visible_height" do
      state.visible_height = 2
      # Only root is visible, so this just exercises the code path
      state.move_down
      expect(state.scroll_offset).to eq(0)
    end
  end
end
