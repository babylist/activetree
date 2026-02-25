# frozen_string_literal: true

module ActiveTree
  class Configuration
    class ModelDsl
      def initialize(model_config)
        @model_config = model_config
      end

      def field(name, label: nil)
        @model_config.configure_field(name, label: label)
      end

      def fields(*entries)
        @model_config.configure_fields(entries)
      end

      def child(name, scope = nil, label: nil)
        @model_config.configure_child(name, label: label, scope: scope)
      end

      def children(*entries)
        @model_config.configure_children(entries)
      end

      def label(&)
        @model_config.configure_label(&)
      end
    end
  end
end
