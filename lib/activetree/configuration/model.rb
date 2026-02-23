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

      def configure_field(name, **kwargs)
        fields[name] = Field.new(name, **kwargs)
      end

      def configure_fields(entries)
        entries.each do |entry|
          if entry.is_a?(Hash)
            entry.each do |name, options|
              configure_field(name, **options)
            end
          else
            configure_field(entry)
          end
        end
      end

      def configure_child(name, **kwargs)
        children[name] = Child.new(name, **kwargs)
      end

      def configure_children(entries)
        entries.each do |entry|
          if entry.is_a?(Hash)
            entry.each do |name, options|
              configure_child(name, **options)
            end
          else
            configure_child(entry)
          end
        end
      end

      def configure_label(&block)
        @label_block = block
      end
    end
  end
end
