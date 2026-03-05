# frozen_string_literal: true

require_relative "../support/shared_examples/list_node"

RSpec.describe ActiveTree::QueryResultsNode do
  let(:tree_state) { ActiveTree::TreeState.new }

  let(:records) { [double("R1", id: 1, class: double(name: "User")), double("R2", id: 2, class: double(name: "User"))] }

  let(:relation) do
    rel = double("Relation")
    allow(rel).to receive(:offset).and_return(rel)
    allow(rel).to receive(:limit).and_return(rel)
    allow(rel).to receive(:to_a).and_return(records)
    rel
  end

  subject(:node) do
    described_class.new(
      relation: relation,
      query_description: "User.where(active: true)",
      tree_state: tree_state
    )
  end

  it "returns false for record?" do
    expect(node.record?).to be false
  end

  it "starts expanded" do
    expect(node.expanded).to be true
  end

  it "returns the relation as base_relation" do
    expect(node.base_relation).to eq(relation)
  end

  describe "#label" do
    it "includes query description" do
      # Accessing children triggers load, which populates count_label
      node.children
      expect(node.label).to include("User.where(active: true)")
    end

    it "includes count label after loading" do
      node.children
      expect(node.label).to include("[2]")
    end
  end

  let(:node_with_many_records) do
    many = (1..26).map { |i| double("R#{i}", id: i, class: double(name: "Item")) }
    many_rel = double("ManyRelation")
    allow(many_rel).to receive(:offset).and_return(many_rel)
    allow(many_rel).to receive(:limit).and_return(many_rel)
    allow(many_rel).to receive(:to_a).and_return(many)

    described_class.new(
      relation: many_rel,
      query_description: "User.all",
      tree_state: tree_state
    )
  end

  it_behaves_like "a ListNode"
end
