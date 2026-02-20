# frozen_string_literal: true

require "active_support/concern"

RSpec.describe ActiveTree::RecordNode do
  describe "with mixin record" do
    let(:record_class) do
      Class.new do
        def self.name
          "Order"
        end

        def self.column_names
          %w[id status total]
        end

        def self.reflect_on_association(_name)
          nil
        end

        def id
          7
        end

        def status
          "shipped"
        end

        def total
          99.99
        end

        include ActiveTree::Model
      end
    end

    let(:record) do
      instance = record_class.new
      record_class.tree_fields :id, :status, :total
      record_class.tree_children :line_items
      instance
    end

    let(:node) { described_class.new(record: record) }

    it "uses tree_node_label for label" do
      expect(node.label).to eq("Order #7")
    end

    it "is expandable when tree_children are configured" do
      expect(node).to be_expandable
    end

    it "returns configured detail_fields" do
      expect(node.detail_fields).to eq(%i[id status total])
    end

    it "returns detail_pairs" do
      pairs = node.detail_pairs
      expect(pairs).to eq([[:id, 7], [:status, "shipped"], [:total, 99.99]])
    end
  end

  describe "with mixin but no fields configured" do
    let(:record_class) do
      Class.new do
        def self.name
          "User"
        end

        def self.column_names
          %w[id name email]
        end

        def id
          42
        end

        include ActiveTree::Model
      end
    end

    let(:record) { record_class.new }
    let(:node) { described_class.new(record: record) }

    it "falls back to all columns for detail_fields" do
      expect(node.detail_fields).to eq(%i[id name email])
    end

    it "is not expandable with no children" do
      expect(node).not_to be_expandable
    end
  end

  describe "without mixin" do
    let(:record) do
      obj = double("PlainRecord", id: 1, class: double(name: "Widget"))
      obj
    end

    let(:node) { described_class.new(record: record) }

    it "uses default label format" do
      expect(node.label).to eq("Widget #1")
    end

    it "shows only :id in detail_fields" do
      expect(node.detail_fields).to eq([:id])
    end

    it "is not expandable" do
      expect(node).not_to be_expandable
    end
  end

  describe "#visible_nodes" do
    let(:record) do
      double("Record", id: 1, class: double(name: "Leaf"))
    end
    let(:node) { described_class.new(record: record) }

    it "returns self when not expanded" do
      expect(node.visible_nodes).to eq([node])
    end
  end
end
