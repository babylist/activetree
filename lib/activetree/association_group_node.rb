# frozen_string_literal: true

module ActiveTree
  class AssociationGroupNode < TreeNode
    attr_reader :record, :association_name, :reflection

    def initialize(record:, association_name:, reflection:, tree_state:, depth: 0, parent: nil)
      super(depth: depth, parent: parent, tree_state:)
      @record = record
      @association_name = association_name
      @reflection = reflection
      @children = nil
      @loaded = false
      @offset = 0
      @has_more = false
    end

    def label
      if @loaded && !singular?
        count_str = @has_more ? "#{@offset}+" : child_record_count.to_s
        "#{association_configuration.label} [#{count_str}]"
      else
        association_configuration.label
      end
    end

    def expandable?
      true
    end

    def children
      load_children! unless @loaded
      @children
    end

    def load_children!
      @children = []
      @loaded = true

      if singular?
        load_singular_association
      else
        load_collection_association
      end
    end

    def load_more!
      return unless @has_more

      new_records = fetch_records(@offset)
      process_fetched_records(new_records)
    end

    private

    def singular?
      %i[has_one belongs_to].include?(reflection.macro)
    end

    def load_singular_association
      associated = if association_configuration&.scope
                     apply_scope(record.association(association_name).scope).first
                   else
                     record.public_send(association_name)
                   end
      return unless associated

      @children << build_record_node(associated)
    end

    def load_collection_association
      records = fetch_records(0)
      @offset = records.size
      append_record_nodes(records)
    end

    def fetch_records(offset)
      limit = ActiveTree.config.default_limit
      base = apply_scope(record.public_send(association_name))
      all = base.offset(offset).limit(limit + 1).to_a

      @has_more = all.size > limit
      all.first(limit)
    end

    def apply_scope(relation)
      return relation unless association_configuration&.scope

      relation.instance_exec(&association_configuration.scope)
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

    def association_configuration
      @association_configuration ||= ActiveTree.config.model_configuration(record.class).children[association_name]
    end
  end
end
