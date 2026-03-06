# frozen_string_literal: true

require "active_record"
module ActiveTree
  class ListNode < TreeNode
    def initialize(tree_state:, depth: 0, parent: nil, relation: nil)
      super(tree_state:, depth:, parent:)
      @children = nil
      @loaded = false
      @offset = 0
      @has_more = false
      @relation = relation
    end

    def expandable?
      true
    end

    def loaded?
      @loaded
    end

    def children
      load_children! unless @loaded
      @children
    end

    def load_children!
      @children = []
      @loaded = true
      records = fetch_records(0)
      @offset = records.size
      append_record_nodes(records)
    end

    def load_more!
      return unless @has_more

      new_records = fetch_records(@offset)
      process_fetched_records(new_records)
    end

    def base_relation
      @relation || ActiveRecord::Relation.new(ActiveRecord::Base).none
    end

    def count_label
      return "" unless @loaded

      count_str = @has_more ? "#{@offset}+" : child_record_count.to_s
      " [#{count_str}]"
    end

    private

    def fetch_records(offset)
      limit = ActiveTree.config.default_limit
      all = base_relation.offset(offset).limit(limit + 1).to_a

      @has_more = all.size > limit
      all.first(limit)
    end

    def process_fetched_records(records)
      @offset += records.size
      remove_load_more_node
      append_record_nodes(records)
    end

    def append_record_nodes(records)
      records.each { |rec| @children << build_record_node(rec) }
      @children << LoadMoreNode.new(group: self, depth: depth + 1, parent: self, tree_state: @tree_state) if @has_more
    end

    def build_record_node(rec)
      RecordNode.new(record: rec, depth: depth + 1, parent: self, tree_state: @tree_state)
    end

    def child_record_count
      @children.count { |c| c.is_a?(RecordNode) }
    end

    def remove_load_more_node
      @children.reject! { |c| c.is_a?(LoadMoreNode) }
    end
  end
end
