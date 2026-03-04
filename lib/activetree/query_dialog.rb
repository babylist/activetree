# frozen_string_literal: true

require "active_support/core_ext/string/inflections"

module ActiveTree
  class QueryDialog < Dialog
    def initialize(model_name: "", query: "")
      super(
        title: "Query",
        fields: [
          DialogField.new(name: :model, label: "Model class", value: model_name),
          DialogField.new(name: :query, label: "Query", value: query)
        ]
      )
    end

    def execute
      model_name = fields[0].value.strip
      query_str = fields[1].value.strip
      validate!(model_name, query_str)

      klass = resolve_model(model_name)
      relation = build_base_relation(klass)

      if numeric?(query_str)
        execute_id_query(relation, query_str, model_name)
      else
        execute_dsl_query(relation, query_str, model_name)
      end
    end

    private

    def validate!(model_name, query_str)
      raise ArgumentError, "Model class is required" if model_name.empty?
      raise ArgumentError, "Query is required" if query_str.empty?
    end

    def resolve_model(model_name)
      model_name.constantize
    rescue NameError
      raise ArgumentError, "Model '#{model_name}' not found"
    end

    def build_base_relation(klass)
      relation = klass.unscoped
      relation = relation.merge(ActiveTree.config.global_scope) if ActiveTree.config.global_scope
      relation
    end

    def numeric?(str)
      str.match?(/\A\d+\z/)
    end

    def execute_id_query(relation, query_str, model_name)
      record = relation.find_by(id: query_str.to_i)
      raise ArgumentError, "#{model_name} with id #{query_str} not found" unless record

      { record: record }
    end

    def execute_dsl_query(relation, query_str, model_name)
      result_relation = relation.instance_eval(query_str)
      peek = result_relation.limit(2).to_a

      raise ArgumentError, "No results for #{model_name}.#{query_str}" if peek.empty?

      if peek.size == 1
        { record: peek.first }
      else
        { relation: relation.instance_eval(query_str), description: "#{model_name}.#{query_str}" }
      end
    rescue ArgumentError
      raise
    rescue StandardError => e
      raise ArgumentError, e.message
    end
  end
end
