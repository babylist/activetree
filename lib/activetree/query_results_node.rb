# frozen_string_literal: true

module ActiveTree
  class QueryResultsNode < ListNode
    attr_reader :query_description

    def initialize(relation:, query_description:, tree_state:)
      super(relation:, tree_state: tree_state, depth: 0)

      @query_description = query_description
      self.expanded = true
    end

    def label
      "#{query_description}#{count_label}"
    end

    def base_relation
      @relation
    end

    def record?
      false
    end
  end
end
