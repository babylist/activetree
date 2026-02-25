# frozen_string_literal: true

require "active_support/concern"

RSpec.describe ActiveTree::AssociationGroupNode do
  let(:tree_state) do
    root_node = double("RootNode", record: double("RootRecord"))
    double("TreeState", root: root_node)
  end

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

  before do
    ActiveTree.config.model_configuration(parent_record.class).configure_child(:items)
  end

  let(:node) do
    described_class.new(
      record: parent_record,
      association_name: :items,
      reflection: reflection,
      tree_state: tree_state,
      depth: 1
    )
  end

  describe "#label" do
    it "shows association name before loading" do
      expect(node.label).to eq("items")
    end

    it "shows count after loading" do
      node.load_children!
      expect(node.label).to eq("items [1]")
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
        tree_state: tree_state,
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

  describe "collection with scope" do
    let(:scope_proc) { -> { where(active: true) } }
    let(:scoped_relation) do
      s = double("ScopedRelation")
      allow(s).to receive(:offset).and_return(s)
      allow(s).to receive(:limit).and_return(s)
      allow(s).to receive(:to_a).and_return([child_record])
      s
    end

    let(:base_relation) do
      s = double("BaseRelation")
      allow(s).to receive(:merge).with(scope_proc).and_return(scoped_relation)
      s
    end

    let(:scoped_parent_record) do
      rec = double("ParentRecord", id: 42)
      allow(rec).to receive(:public_send).with(:items).and_return(base_relation)
      rec
    end

    let(:scoped_node) do
      described_class.new(
        record: scoped_parent_record,
        association_name: :items,
        reflection: reflection,
        tree_state: tree_state,
        depth: 1
      )
    end

    before do
      child_config = ActiveTree::Configuration::Model::Child.new(:items, scope: scope_proc)
      model_config = ActiveTree.config.model_configuration(scoped_parent_record.class)
      model_config.children[:items] = child_config
    end

    it "merges child scope onto the relation before offset/limit" do
      scoped_node.load_children!
      expect(scoped_node.children.size).to eq(1)
      expect(scoped_node.children.first).to be_a(ActiveTree::RecordNode)
    end
  end

  describe "collection without scope" do
    it "does not call merge on the relation" do
      expect(scope).not_to receive(:merge)
      node.load_children!
      expect(node.children.size).to eq(1)
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

    before do
      ActiveTree.config.model_configuration(owner_record.class).configure_child(:user)
    end

    let(:singular_node) do
      described_class.new(
        record: owner_record,
        association_name: :user,
        reflection: singular_reflection,
        tree_state: tree_state,
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

    it "does not call association().scope when no scope configured" do
      expect(owner_record).not_to receive(:association)
      singular_node.load_children!
    end
  end

  describe "singular association with scope" do
    let(:singular_reflection) { double("Reflection", macro: :has_one) }
    let(:scope_proc) { -> { where(primary: true) } }
    let(:associated_record) { double("Associated", id: 5, class: double(name: "Address")) }

    let(:scoped_relation) do
      s = double("ScopedRelation")
      allow(s).to receive(:first).and_return(associated_record)
      s
    end

    let(:association_relation) do
      s = double("AssociationRelation")
      allow(s).to receive(:merge).with(scope_proc).and_return(scoped_relation)
      s
    end

    let(:association_proxy) do
      double("AssociationProxy", scope: association_relation)
    end

    let(:owner_record) do
      rec = double("OwnerRecord", id: 1)
      allow(rec).to receive(:association).with(:address).and_return(association_proxy)
      rec
    end

    let(:scoped_singular_node) do
      described_class.new(
        record: owner_record,
        association_name: :address,
        reflection: singular_reflection,
        tree_state: tree_state,
        depth: 1
      )
    end

    before do
      child_config = ActiveTree::Configuration::Model::Child.new(:address, scope: scope_proc)
      model_config = ActiveTree.config.model_configuration(owner_record.class)
      model_config.children[:address] = child_config
    end

    it "loads via association scope and merges the scope proc" do
      scoped_singular_node.load_children!
      expect(scoped_singular_node.children.size).to eq(1)
      expect(scoped_singular_node.children.first).to be_a(ActiveTree::RecordNode)
    end

    it "handles nil result from scoped query" do
      allow(scoped_relation).to receive(:first).and_return(nil)
      scoped_singular_node.load_children!
      expect(scoped_singular_node.children).to be_empty
    end
  end

  describe "collection with global_scope" do
    let(:global_scope_proc) { -> { where(org_id: 1) } }

    let(:globally_scoped_relation) do
      s = double("GloballyScopedRelation")
      allow(s).to receive(:offset).and_return(s)
      allow(s).to receive(:limit).and_return(s)
      allow(s).to receive(:to_a).and_return([child_record])
      s
    end

    let(:base_relation) do
      s = double("BaseRelation")
      allow(s).to receive(:merge).with(global_scope_proc).and_return(globally_scoped_relation)
      s
    end

    let(:global_scope_parent) do
      rec = double("ParentRecord", id: 42)
      allow(rec).to receive(:public_send).with(:items).and_return(base_relation)
      rec
    end

    before do
      ActiveTree.config.global_scope = global_scope_proc
      ActiveTree.config.model_configuration(global_scope_parent.class).configure_child(:items)
    end

    let(:global_scope_node) do
      described_class.new(
        record: global_scope_parent,
        association_name: :items,
        reflection: reflection,
        tree_state: tree_state,
        depth: 1
      )
    end

    it "applies global_scope to collection queries" do
      global_scope_node.load_children!
      expect(global_scope_node.children.size).to eq(1)
      expect(global_scope_node.children.first).to be_a(ActiveTree::RecordNode)
    end
  end

  describe "collection with global_scope and child scope" do
    let(:global_scope_proc) { -> { where(org_id: 1) } }
    let(:child_scope_proc) { -> { where(active: true) } }

    let(:final_relation) do
      s = double("FinalRelation")
      allow(s).to receive(:offset).and_return(s)
      allow(s).to receive(:limit).and_return(s)
      allow(s).to receive(:to_a).and_return([child_record])
      s
    end

    let(:after_global_relation) do
      s = double("AfterGlobalRelation")
      allow(s).to receive(:merge).with(child_scope_proc).and_return(final_relation)
      s
    end

    let(:base_relation) do
      s = double("BaseRelation")
      allow(s).to receive(:merge).with(global_scope_proc).and_return(after_global_relation)
      s
    end

    let(:chained_parent) do
      rec = double("ParentRecord", id: 42)
      allow(rec).to receive(:public_send).with(:items).and_return(base_relation)
      rec
    end

    before do
      ActiveTree.config.global_scope = global_scope_proc
      child_config = ActiveTree::Configuration::Model::Child.new(:items, scope: child_scope_proc)
      model_config = ActiveTree.config.model_configuration(chained_parent.class)
      model_config.children[:items] = child_config
    end

    let(:chained_node) do
      described_class.new(
        record: chained_parent,
        association_name: :items,
        reflection: reflection,
        tree_state: tree_state,
        depth: 1
      )
    end

    it "applies global_scope first, then child scope" do
      chained_node.load_children!
      expect(chained_node.children.size).to eq(1)
      expect(chained_node.children.first).to be_a(ActiveTree::RecordNode)
    end
  end

  describe "singular association with global_scope" do
    let(:singular_reflection) { double("Reflection", macro: :belongs_to) }
    let(:global_scope_proc) { -> { where(org_id: 1) } }
    let(:associated_record) { double("Associated", id: 5, class: double(name: "User")) }

    let(:scoped_relation) do
      s = double("ScopedRelation")
      allow(s).to receive(:first).and_return(associated_record)
      s
    end

    let(:association_relation) do
      s = double("AssociationRelation")
      allow(s).to receive(:merge).with(global_scope_proc).and_return(scoped_relation)
      s
    end

    let(:association_proxy) do
      double("AssociationProxy", scope: association_relation)
    end

    let(:owner_record) do
      rec = double("OwnerRecord", id: 1)
      allow(rec).to receive(:association).with(:user).and_return(association_proxy)
      rec
    end

    before do
      ActiveTree.config.global_scope = global_scope_proc
      ActiveTree.config.model_configuration(owner_record.class).configure_child(:user)
    end

    let(:global_scope_singular_node) do
      described_class.new(
        record: owner_record,
        association_name: :user,
        reflection: singular_reflection,
        tree_state: tree_state,
        depth: 1
      )
    end

    it "uses relation path and applies global_scope" do
      global_scope_singular_node.load_children!
      expect(global_scope_singular_node.children.size).to eq(1)
      expect(global_scope_singular_node.children.first).to be_a(ActiveTree::RecordNode)
    end

    it "handles nil result" do
      allow(scoped_relation).to receive(:first).and_return(nil)
      global_scope_singular_node.load_children!
      expect(global_scope_singular_node.children).to be_empty
    end
  end
end
