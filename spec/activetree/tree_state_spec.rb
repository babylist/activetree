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

      it "clamps scroll_offset when collapsing makes content fit in viewport" do
        state_with_children.visible_height = 5
        # Force a stale scroll_offset as if the user had scrolled down
        state_with_children.instance_variable_set(:@scroll_offset, 3)
        # Collapse the root — only 1 node remains, which fits in the viewport
        state_with_children.toggle_expand
        expect(state_with_children.scroll_offset).to eq(0)
      end

      it "clamps scroll_offset to partial overflow after collapse" do
        state_with_children.visible_height = 1
        state_with_children.instance_variable_set(:@scroll_offset, 5)
        # Root expanded has 2 visible nodes (root + association group).
        # With visible_height=1, max_offset = 2 - 1 = 1.
        # After collapse only root remains, max_offset = 1 - 1 = 0.
        state_with_children.toggle_expand
        expect(state_with_children.scroll_offset).to eq(0)
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

  describe "#toggle_focus" do
    it "switches from tree to detail" do
      expect(state.focused_pane).to eq(:tree)
      state.toggle_focus
      expect(state.focused_pane).to eq(:detail)
    end

    it "switches from detail back to tree" do
      state.toggle_focus
      state.toggle_focus
      expect(state.focused_pane).to eq(:tree)
    end
  end

  describe "#navigate_right" do
    context "when detail pane is focused" do
      it "is a no-op" do
        state.toggle_focus
        expect(state.focused_pane).to eq(:detail)
        state.navigate_right
        expect(state.focused_pane).to eq(:detail)
      end
    end

    context "with an expandable tree" do
      let(:reflection) { Struct.new(:macro).new(:has_many) }

      let(:record_with_children) do
        reflection_ref = reflection
        klass = Class.new do
          define_singleton_method(:name) { "Order" }
          define_singleton_method(:reflect_on_association) { |name| reflection_ref if name == :items }
          define_method(:id) { 1 }
          include ActiveTree::Model
        end
        klass.tree_children :items
        klass.new
      end

      let(:nav_state) { described_class.new(root_record: record_with_children) }

      it "expands a collapsed expandable node" do
        nav_state.root.expanded = false
        nav_state.navigate_right
        expect(nav_state.root.expanded).to be true
      end

      it "moves to first child when node is expanded with children" do
        # Root is expanded by default and has an AssociationGroupNode child for :items
        expect(nav_state.root.expanded).to be true
        expect(nav_state.visible_nodes.size).to be > 1
        nav_state.navigate_right
        expect(nav_state.cursor_index).to eq(1)
      end

      it "selects and focuses detail on a leaf node" do
        # Collapse root so it's not expandable-looking, then use a plain record
        # Use the simple state with a non-expandable root
        state.navigate_right
        expect(state.selected_record_node).to eq(state.root)
        expect(state.focused_pane).to eq(:detail)
      end
    end

    context "with a LoadMoreNode" do
      it "activates the load more node" do
        load_more = instance_double(ActiveTree::LoadMoreNode)
        allow(load_more).to receive(:is_a?).with(ActiveTree::LoadMoreNode).and_return(true)
        allow(load_more).to receive(:activate!)
        allow(state).to receive(:cursor_node).and_return(load_more)

        state.navigate_right
        expect(load_more).to have_received(:activate!)
      end
    end
  end

  describe "#navigate_left" do
    context "when detail pane is focused" do
      it "focuses the tree pane" do
        state.toggle_focus
        expect(state.focused_pane).to eq(:detail)
        state.navigate_left
        expect(state.focused_pane).to eq(:tree)
      end
    end

    context "with an expandable tree" do
      let(:reflection) { Struct.new(:macro).new(:has_many) }

      let(:record_with_children) do
        reflection_ref = reflection
        klass = Class.new do
          define_singleton_method(:name) { "Order" }
          define_singleton_method(:reflect_on_association) { |name| reflection_ref if name == :items }
          define_method(:id) { 1 }
          include ActiveTree::Model
        end
        klass.tree_children :items
        klass.new
      end

      let(:nav_state) { described_class.new(root_record: record_with_children) }

      it "collapses an expanded node" do
        expect(nav_state.root.expanded).to be true
        nav_state.navigate_left
        expect(nav_state.root.expanded).to be false
      end

      it "clamps scroll_offset when collapsing via navigate_left" do
        nav_state.visible_height = 5
        nav_state.instance_variable_set(:@scroll_offset, 3)
        nav_state.navigate_left
        expect(nav_state.scroll_offset).to eq(0)
      end

      it "moves to parent when node is collapsed" do
        # Root is expanded, so visible_nodes includes the AssociationGroupNode child
        nav_state.move_down
        expect(nav_state.cursor_index).to eq(1)

        child = nav_state.cursor_node
        expect(child.parent).to eq(nav_state.root)
        # AssociationGroupNode is expandable but collapsed by default
        expect(child.expanded).to be false

        nav_state.navigate_left
        expect(nav_state.cursor_index).to eq(0)
      end
    end

    context "on root node" do
      it "is a no-op" do
        state.navigate_left
        expect(state.cursor_index).to eq(0)
      end
    end
  end

  describe "#detail_focused? / #tree_focused?" do
    it "reports tree focused by default" do
      expect(state.tree_focused?).to be true
      expect(state.detail_focused?).to be false
    end

    it "reports detail focused after toggle" do
      state.toggle_focus
      expect(state.tree_focused?).to be false
      expect(state.detail_focused?).to be true
    end
  end

  describe "#scroll_detail_up" do
    it "clamps at 0" do
      state.scroll_detail_up
      expect(state.detail_scroll_offset).to eq(0)
    end

    it "decrements when offset is positive" do
      state.detail_content_height = 30
      state.visible_height = 10
      3.times { state.scroll_detail_down }
      state.scroll_detail_up
      expect(state.detail_scroll_offset).to eq(2)
    end
  end

  describe "#scroll_detail_down" do
    it "stays at 0 when content fits in viewport" do
      state.detail_content_height = 5
      state.visible_height = 10
      state.scroll_detail_down
      expect(state.detail_scroll_offset).to eq(0)
    end

    it "increments when content overflows" do
      state.detail_content_height = 30
      state.visible_height = 10
      state.scroll_detail_down
      expect(state.detail_scroll_offset).to eq(1)
    end

    it "clamps at max_offset" do
      state.detail_content_height = 12
      state.visible_height = 10
      10.times { state.scroll_detail_down }
      expect(state.detail_scroll_offset).to eq(2)
    end
  end

  describe "#field_mode" do
    it "defaults to :config for any class" do
      expect(state.field_mode(record.class)).to eq(:config)
    end
  end

  describe "#toggle_field_mode" do
    it "switches from :config to :all_columns" do
      state.toggle_field_mode
      expect(state.field_mode(record.class)).to eq(:all_columns)
    end

    it "switches back to :config on second toggle" do
      state.toggle_field_mode
      state.toggle_field_mode
      expect(state.field_mode(record.class)).to eq(:config)
    end

    it "resets detail_scroll_offset to 0" do
      state.detail_content_height = 30
      state.visible_height = 10
      5.times { state.scroll_detail_down }
      expect(state.detail_scroll_offset).to eq(5)
      state.toggle_field_mode
      expect(state.detail_scroll_offset).to eq(0)
    end

    it "scopes mode per class name" do
      other_record = double("Record", id: 2, class: double(name: "Order"))
      other_state = described_class.new(root_record: other_record)

      state.toggle_field_mode
      expect(state.field_mode(record.class)).to eq(:all_columns)
      expect(other_state.field_mode(other_record.class)).to eq(:config)
    end
  end

  describe "#cursor_up" do
    it "calls move_up when tree is focused" do
      allow(state).to receive(:move_up)
      state.cursor_up
      expect(state).to have_received(:move_up)
    end

    it "calls scroll_detail_up when detail is focused" do
      state.toggle_focus
      allow(state).to receive(:scroll_detail_up)
      state.cursor_up
      expect(state).to have_received(:scroll_detail_up)
    end
  end

  describe "#cursor_down" do
    it "calls move_down when tree is focused" do
      allow(state).to receive(:move_down)
      state.cursor_down
      expect(state).to have_received(:move_down)
    end

    it "calls scroll_detail_down when detail is focused" do
      state.toggle_focus
      allow(state).to receive(:scroll_detail_down)
      state.cursor_down
      expect(state).to have_received(:scroll_detail_down)
    end
  end

  describe "#empty?" do
    it "returns true when initialized without root_record" do
      empty_state = described_class.new
      expect(empty_state.empty?).to be true
    end

    it "returns false when root_record is provided" do
      expect(state.empty?).to be false
    end
  end

  describe "#set_root_record" do
    it "sets root and resets cursor/scroll" do
      other_record = double("Record", id: 99, class: double(name: "Order"))
      state.instance_variable_set(:@cursor_index, 5)
      state.instance_variable_set(:@scroll_offset, 3)
      state.set_root_record(other_record)
      expect(state.root.record).to eq(other_record)
      expect(state.cursor_index).to eq(0)
      expect(state.scroll_offset).to eq(0)
    end
  end

  describe "#set_root_node" do
    it "sets root to arbitrary node and resets cursor/scroll" do
      node = double("Node")
      state.instance_variable_set(:@cursor_index, 5)
      state.instance_variable_set(:@scroll_offset, 3)
      state.set_root_node(node)
      expect(state.root).to eq(node)
      expect(state.cursor_index).to eq(0)
      expect(state.scroll_offset).to eq(0)
      expect(state.selected_record_node).to be_nil
    end
  end

  describe "#visible_nodes when empty" do
    it "returns empty array" do
      empty_state = described_class.new
      expect(empty_state.visible_nodes).to eq([])
    end
  end

  describe "#cursor_node when empty" do
    it "returns nil" do
      empty_state = described_class.new
      expect(empty_state.cursor_node).to be_nil
    end
  end

  describe "#select_current resets detail scroll" do
    it "resets detail_scroll_offset to 0" do
      state.detail_content_height = 30
      state.visible_height = 10
      5.times { state.scroll_detail_down }
      expect(state.detail_scroll_offset).to eq(5)
      state.select_current
      expect(state.detail_scroll_offset).to eq(0)
    end
  end
end
