# frozen_string_literal: true

module ActiveTree
  class RecordNode < TreeNode
    attr_reader :record

    def initialize(record:, tree_state:, depth: 0, parent: nil)
      super(depth: depth, parent: parent, tree_state: tree_state)
      @record = record
      @children = nil
    end

    def label
      if record.respond_to?(:tree_node_label)
        record.tree_node_label
      else
        "#{record.class.name} ##{record.id}"
      end
    end

    def class_label
      record&.class&.name || "Record"
    end

    def expandable?
      # Can only expand root record if root node
      return false if (@tree_state.root.record == record) && (self != @tree_state.root)

      configured_children.any?
    end

    def children
      @children ||= build_children
    end

    def detail_fields
      if record.respond_to?(:tree_node_fields) && record.tree_node_fields
        record.tree_node_fields
      elsif record.respond_to?(:tree_node_fields)
        record.class.column_names.map(&:to_sym)
      else
        [:id]
      end
    end

    def detail_pairs
      detail_fields.map do |field|
        [field, record.public_send(field)]
      end
    end

    def record?
      true
    end

    private

    def configured_children
      if record.respond_to?(:tree_node_children)
        record.tree_node_children
      else
        []
      end
    end

    def build_children
      configured_children.filter_map do |assoc_name|
        build_association_node(assoc_name)
      end
    end

    def build_association_node(assoc_name)
      reflection = record.class.reflect_on_association(assoc_name)
      return unless reflection

      AssociationGroupNode.new(
        record: record,
        association_name: assoc_name,
        reflection: reflection,
        depth: depth + 1,
        parent: self,
        tree_state: @tree_state
      )
    end
  end
end
