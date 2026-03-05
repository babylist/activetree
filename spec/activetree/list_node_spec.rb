# frozen_string_literal: true

require_relative "../support/shared_examples/list_node"
RSpec.describe ActiveTree::ListNode do
  let(:tree_state) { ActiveTree::TreeState.new }

  let(:records) { (1..3).map { |i| double("Record#{i}", id: i, class: double(name: "Item")) } }
  let(:many_records) { (1..26).map { |i| double("R#{i}", id: i, class: double(name: "Item")) } }

  let(:relation) do
    rel = double("Relation", to_a: records)
    allow(rel).to receive(:offset).and_return(rel)
    allow(rel).to receive(:limit).and_return(rel)
    rel
  end

  let(:relation_with_many_records) do
    rel = double("Relation", to_a: many_records)
    allow(rel).to receive(:offset).and_return(rel)
    allow(rel).to receive(:limit).and_return(rel)
    rel
  end

  subject(:node) { described_class.new(relation:, tree_state: tree_state) }

  let(:node_with_many_records) do
    described_class.new(relation: relation_with_many_records, tree_state: tree_state)
  end

  it_behaves_like "a ListNode"
end
