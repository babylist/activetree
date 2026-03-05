# frozen_string_literal: true

module ActiveTree
  class AssociationGroupNode < ListNode
    attr_reader :record, :association_name, :reflection

    def initialize(record:, association_name:, reflection:, tree_state:, depth: 0, parent: nil)
      super(relation: nil, tree_state: tree_state, depth: depth, parent: parent)
      @record = record
      @association_name = association_name
      @reflection = reflection
    end

    def label
      if singular?
        association_configuration.label
      else
        "#{association_configuration.label}#{count_label}"
      end
    end

    def load_children!
      if singular?
        @children = []
        @loaded = true
        load_singular_association
      else
        super
      end
    end

    def base_relation
      apply_scope(record.public_send(association_name))
    end

    private

    def singular?
      %i[has_one belongs_to].include?(reflection.macro)
    end

    def load_singular_association
      associated = if association_configuration&.scope || ActiveTree.config.global_scope
                     apply_scope(record.association(association_name).scope).first
                   else
                     record.public_send(association_name)
                   end
      return unless associated

      @children << build_record_node(associated)
    end

    def apply_scope(relation)
      relation = relation.merge(ActiveTree.config.global_scope) if ActiveTree.config.global_scope
      return relation unless association_configuration&.scope

      relation.merge(association_configuration.scope)
    end

    def association_configuration
      @association_configuration ||= ActiveTree.config.model_configuration(record.class).children[association_name]
    end
  end
end
