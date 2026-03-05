# frozen_string_literal: true

# Shared examples for ListNode subclasses.
#
# The host spec must define:
#   node                    — instance backed by a small record set
#   node_with_many_records  — instance whose relation returns 26 records
#   relation                — the underlying relation double (for stubbing)

RSpec.shared_examples "a ListNode" do
  describe "#expandable?" do
    it "is always expandable" do
      expect(node).to be_expandable
    end
  end

  describe "#loaded?" do
    it "is false before children are loaded" do
      expect(node).not_to be_loaded
    end

    it "is true after load_children!" do
      node.load_children!
      expect(node).to be_loaded
    end

    it "is true after children are accessed (lazy load)" do
      node.children
      expect(node).to be_loaded
    end
  end

  describe "#children" do
    it "lazy-loads and returns RecordNodes" do
      children = node.children
      expect(node).to be_loaded
      expect(children).to all(be_a(ActiveTree::RecordNode))
    end
  end

  describe "pagination" do
    it "inserts LoadMoreNode when more records exist" do
      node_with_many_records.load_children!
      expect(node_with_many_records.children.last).to be_a(ActiveTree::LoadMoreNode)
    end

    it "limits to 25 RecordNodes" do
      node_with_many_records.load_children!
      record_nodes = node_with_many_records.children.select { |c| c.is_a?(ActiveTree::RecordNode) }
      expect(record_nodes.size).to eq(25)
    end
  end

  describe "#count_label" do
    it "is empty when not loaded" do
      expect(node.count_label).to eq("")
    end

    it "shows count after load" do
      node.load_children!
      expect(node.count_label).to match(/\[\d+\]/)
    end

    it "shows 25+ when has_more" do
      node_with_many_records.load_children!
      expect(node_with_many_records.count_label).to eq(" [25+]")
    end
  end

  describe "#load_more!" do
    it "is a no-op when has_more is false" do
      node.load_children!
      expect { node.load_more! }.not_to(change { node.children.size })
    end

    context "when there are more records" do
      let(:page1) { (1..26).map { |i| double("R#{i}", id: i, class: double(name: "Item")) } }
      let(:page2) { (26..28).map { |i| double("R#{i}", id: i, class: double(name: "Item")) } }

      it "fetches next page and removes old LoadMoreNode" do
        call_count = 0
        allow(relation).to receive(:to_a) do
          call_count += 1
          call_count == 1 ? page1 : page2
        end

        node.load_children!
        expect(node.children.last).to be_a(ActiveTree::LoadMoreNode)
        initial_record_count = node.children.count { |c| c.is_a?(ActiveTree::RecordNode) }

        node.load_more!
        new_record_count = node.children.count { |c| c.is_a?(ActiveTree::RecordNode) }
        expect(new_record_count).to be > initial_record_count
      end
    end
  end
end
