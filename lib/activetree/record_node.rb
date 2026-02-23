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
      @label ||= model_configuration.label(record)
    end

    def class_label
      record&.class&.name || "Record"
    end

    def expandable?
      # Can only expand root record if root node
      return false if (@tree_state.root.record == record) && (self != @tree_state.root)

      children.any?
    end

    def children
      @children ||= build_children
    end

    def detail_fields
      @detail_fields ||= if model_configuration.fields.any?
                           model_configuration.fields.values
                         else
                           [:id]
                         end
    end

    def detail_pairs
      @detail_pairs ||= detail_fields.map do |field|
        [field.label, record.public_send(field.name)]
      end
    end

    def record?
      true
    end

    private

    def model_configuration
      @model_configuration ||= ActiveTree.config.model_configuration(record.class)
    end

    def configured_children
      model_configuration.children
    end

    def build_children
      configured_children.values.map(&:name).filter_map do |assoc_name|
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
