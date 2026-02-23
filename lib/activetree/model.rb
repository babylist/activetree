# frozen_string_literal: true

require "active_support/concern"
require "active_support/core_ext/class/attribute"

module ActiveTree
  module Model
    extend ActiveSupport::Concern

    class_methods do
      def tree_configuration
        ActiveTree.config.model_configuration(self)
      end

      def tree_field(name, label = nil)
        tree_configuration.configure_field(name, label)
      end

      def tree_fields(*field_names)
        tree_configuration.configure_fields(*field_names)
      end

      def tree_child(name, label = nil)
        tree_configuration.configure_child(name, label)
      end

      def tree_children(*association_names)
        tree_configuration.configure_children(*association_names)
      end

      def tree_label(&block)
        tree_configuration.configure_label(&block)
      end
    end
  end
end
