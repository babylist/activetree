# frozen_string_literal: true

require "active_support/concern"
require "active_support/core_ext/class/attribute"

module ActiveTree
  module Model
    extend ActiveSupport::Concern

    included do
      class_attribute :_tree_fields, instance_writer: false
      class_attribute :_tree_children, instance_writer: false, default: []
      class_attribute :_tree_label_block, instance_writer: false
    end

    class_methods do
      def tree_fields(*fields)
        self._tree_fields = fields
      end

      def tree_children(*assocs)
        self._tree_children = assocs
      end

      def tree_label(&block)
        self._tree_label_block = block
      end
    end

    def tree_node_label
      if self.class._tree_label_block
        self.class._tree_label_block.call(self)
      else
        "#{self.class.name} ##{id}"
      end
    end

    def tree_node_fields
      self.class._tree_fields
    end

    def tree_node_children
      self.class._tree_children
    end
  end
end
