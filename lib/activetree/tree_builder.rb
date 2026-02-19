# frozen_string_literal: true

module ActiveTree
  class TreeBuilder
    def initialize(config: ActiveTree.config)
      @config = config
    end

    def discover!
      return [] unless defined?(ActiveRecord::Base)

      ActiveRecord::Base.descendants.reject do |model|
        model.abstract_class? || @config.excluded_models.include?(model.name)
      end
    end

    def to_tree_data
      models = discover!
      return { "No models found" => [] } if models.empty?

      tree = {}
      models.sort_by(&:name).each do |model|
        tree[model.name] = build_model_node(model)
      end

      { "Models" => tree.map { |k, v| { k => v } } }
    end

    private

    def build_model_node(model)
      children = []
      children.concat(association_nodes(model))
      children.concat(column_nodes(model))
      children
    end

    def association_nodes(model)
      model.reflect_on_all_associations.map do |assoc|
        "#{assoc.macro} :#{assoc.name}"
      end
    rescue StandardError
      []
    end

    def column_nodes(model)
      model.columns.map do |col|
        "#{col.name} (#{col.type})"
      end
    rescue StandardError
      []
    end
  end
end
