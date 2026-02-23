# frozen_string_literal: true

require_relative "model/field"
require_relative "model/child"

module ActiveTree
  class Configuration
    class Model
      attr_reader :model_class, :fields, :children

      def initialize(model_class)
        @model_class = model_class
        @label_block = ->(instance) { "#{instance.class.name} ##{instance.id}" }
        @fields = {}
        @children = {}
      end

      def label(instance)
        @label_block&.call(instance)
      end

      def configure_field(name, label = nil)
        fields[name] = Field.new(name, label)
      end

      def configure_fields(*names)
        names.each { |name| configure_field(name) }
      end

      def configure_child(name, label = nil)
        children[name] = Child.new(name, label)
      end

      def configure_children(*names)
        names.each { |name| configure_child(name) }
      end

      def configure_label(&block)
        @label_block = block
      end
    end
  end
end
