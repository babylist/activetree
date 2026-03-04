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

    context "when tree pane is focused" do
      it "uses thick border for tree and light for detail" do
        expect(TTY::Box).to receive(:frame)
          .with(hash_including(border: :thick)).once.ordered.and_call_original
        expect(TTY::Box).to receive(:frame)
          .with(hash_including(border: :light)).once.ordered.and_call_original
        renderer.render
      end
    end

    context "when detail pane is focused" do
      before { state.toggle_focus }

      it "uses light border for tree and thick for detail" do
        expect(TTY::Box).to receive(:frame)
          .with(hash_including(border: :light)).once.ordered.and_call_original
        expect(TTY::Box).to receive(:frame)
          .with(hash_including(border: :thick)).once.ordered.and_call_original
        renderer.render
      end
    end

    context "expand icon indicators" do
      let(:reflection) { double("Reflection", macro: :has_many) }
      let(:child_record) { double("ChildRecord", id: 1, class: double(name: "Item")) }

      let(:scope) do
        s = double("Scope")
        allow(s).to receive(:offset).and_return(s)
        allow(s).to receive(:limit).and_return(s)
        allow(s).to receive(:to_a).and_return([child_record])
        s
      end

      let(:record_class) { double("RecordClass", name: "Order") }

      let(:record) do
        obj = double("Record", id: 42, class: record_class)
        allow(obj).to receive(:public_send).with(:items).and_return(scope)
        allow(obj).to receive(:public_send).with(:id).and_return(42)
        obj
      end

      before do
        allow(record_class).to receive(:reflect_on_association).with(:items).and_return(reflection)
        ActiveTree.config.model_configuration(record_class).configure_child(:items)
      end

      it "uses hollow arrow for unloaded collapsed node" do
        output = renderer.render
        expect(output).to include("\u25b7") # hollow right arrow (unloaded + collapsed)
      end

      it "uses solid down arrow for loaded expanded node" do
        assoc_node = state.visible_nodes.find { |n| n.is_a?(ActiveTree::AssociationGroupNode) }
        assoc_node.expanded = true
        output = renderer.render
        expect(output).to include("\u25bc") # solid down arrow (loaded + expanded)
      end

      it "uses solid right arrow for loaded collapsed node" do
        assoc_node = state.visible_nodes.find { |n| n.is_a?(ActiveTree::AssociationGroupNode) }
        assoc_node.load_children!
        assoc_node.expanded = false
        output = renderer.render
        expect(output).to include("\u25b6") # solid right arrow (loaded + collapsed)
      end
    end

    context "field mode indicator" do
      it "shows 'Field mode: configured' by default" do
        expect(output).to include("Field mode: configured")
      end

      it "shows 'Field mode: all columns' after toggle" do
        allow(record.class).to receive(:column_names).and_return(%w[id])
        allow(record).to receive(:public_send).with("id").and_return(42)
        state.toggle_field_mode
        expect(renderer.render).to include("Field mode: all columns")
      end
    end

    context "field mode toggle in detail pane" do
      let(:record_class) do
        Class.new do
          def self.name
            "Widget"
          end

          def self.column_names
            %w[id name color weight]
          end

          def id
            1
          end

          def name
            "Sprocket"
          end

          def color
            "red"
          end

          def weight
            3.5
          end

          include ActiveTree::Model
        end
      end

      let(:record) do
        klass = record_class
        klass.tree_fields :id, :name
        klass.new
      end

      it "renders configured fields by default" do
        output = renderer.render
        expect(output).to include("id")
        expect(output).to include("name")
        expect(output).not_to include("color")
        expect(output).not_to include("weight")
      end

      it "renders all columns after toggle" do
        state.toggle_field_mode
        output = renderer.render
        expect(output).to include("id")
        expect(output).to include("name")
        expect(output).to include("color")
        expect(output).to include("weight")
      end
    end

    context "when a field value is an exception" do
      let(:record_class) do
        Class.new do
          def self.name
            "Widget"
          end

          def self.column_names
            %w[id broken_field]
          end

          def id
            1
          end

          def broken_field
            raise NoMethodError, "undefined method"
          end

          include ActiveTree::Model
        end
      end

      let(:record) do
        klass = record_class
        klass.tree_fields :id, :broken_field
        klass.new
      end

      it "renders the exception class name in red" do
        output = renderer.render
        expect(output).to include("NoMethodError")
      end
    end

    it "includes 'f fields' in the help bar" do
      expect(output).to include("f fields")
    end

    context "when the detail title exceeds the pane width" do
      let(:record) do
        obj = double("Record", id: 42, class: double(name: "VeryLongModuleName::VeryLongClassName"))
        allow(obj).to receive(:respond_to?).with(:tree_node_label).and_return(true)
        allow(obj).to receive(:tree_node_label).and_return("some_really_long_label_that_wont_fit@example.com (42)")
        allow(obj).to receive(:respond_to?).with(:tree_node_fields).and_return(false)
        allow(obj).to receive(:respond_to?).with(:tree_node_children).and_return(false)
        obj
      end

      before do
        allow(TTY::Screen).to receive(:width).and_return(60)
      end

      it "truncates the title with an ellipsis" do
        full_title = "[VeryLongModuleName::VeryLongClassName] some_really_long_label_that_wont_fit@example.com (42)"
        expect(output).not_to include(full_title)
        expect(output).to include("\u2026")
      end
    end
  end
end
