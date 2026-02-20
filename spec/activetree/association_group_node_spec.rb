# frozen_string_literal: true

require "active_support/concern"

RSpec.describe ActiveTree::AssociationGroupNode do
  let(:reflection) { double("Reflection", macro: :has_many) }
  let(:child_record) { double("ChildRecord", id: 1, class: double(name: "Item")) }

  let(:scope) do
    s = double("Scope")
    allow(s).to receive(:offset).and_return(s)
    allow(s).to receive(:limit).and_return(s)
    allow(s).to receive(:to_a).and_return([child_record])
    s
  end

  let(:parent_record) do
    rec = double("ParentRecord", id: 42)
    allow(rec).to receive(:public_send).with(:items).and_return(scope)
    rec
  end

  let(:node) do
    described_class.new(
      record: parent_record,
      association_name: :items,
      reflection: reflection,
      depth: 1
    )
  end

  describe "#label" do
    it "shows association name and macro before loading" do
      expect(node.label).to eq("items (has_many)")
    end

    it "shows count after loading" do
      node.load_children!
      expect(node.label).to eq("items (has_many) [1]")
    end
  end

  describe "#expandable?" do
    it "is always expandable" do
      expect(node).to be_expandable
    end
  end

  describe "#children" do
    it "lazy-loads on first access" do
      children = node.children
      expect(children.size).to eq(1)
      expect(children.first).to be_a(ActiveTree::RecordNode)
    end
  end

  describe "pagination" do
    let(:many_records) do
      (1..26).map { |i| double("Record#{i}", id: i, class: double(name: "Item")) }
    end

    let(:paginated_scope) do
      s = double("PaginatedScope")
      allow(s).to receive(:offset).and_return(s)
      allow(s).to receive(:limit).and_return(s)
      allow(s).to receive(:to_a).and_return(many_records)
      s
    end

    let(:paginated_record) do
      rec = double("ParentRecord", id: 42)
      allow(rec).to receive(:public_send).with(:items).and_return(paginated_scope)
      rec
    end

    let(:paginated_node) do
      described_class.new(
        record: paginated_record,
        association_name: :items,
        reflection: reflection,
        depth: 1
      )
    end

    it "inserts LoadMoreNode when more records exist" do
      paginated_node.load_children!
      last_child = paginated_node.children.last
      expect(last_child).to be_a(ActiveTree::LoadMoreNode)
    end

    it "limits to default_limit records" do
      paginated_node.load_children!
      record_nodes = paginated_node.children.select { |c| c.is_a?(ActiveTree::RecordNode) }
      expect(record_nodes.size).to eq(25)
    end
  end

  describe "singular association" do
    let(:singular_reflection) { double("Reflection", macro: :belongs_to) }
    let(:associated_record) { double("Associated", id: 5, class: double(name: "User")) }

    let(:owner_record) do
      rec = double("OwnerRecord", id: 1)
      allow(rec).to receive(:public_send).with(:user).and_return(associated_record)
      rec
    end

    let(:singular_node) do
      described_class.new(
        record: owner_record,
        association_name: :user,
        reflection: singular_reflection,
        depth: 1
      )
    end

    it "loads singular association as single child" do
      singular_node.load_children!
      expect(singular_node.children.size).to eq(1)
      expect(singular_node.children.first).to be_a(ActiveTree::RecordNode)
    end

    it "handles nil singular association" do
      allow(owner_record).to receive(:public_send).with(:user).and_return(nil)
      singular_node.load_children!
      expect(singular_node.children).to be_empty
    end
  end
end
