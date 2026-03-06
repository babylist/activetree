# frozen_string_literal: true

require "active_support/core_ext/string/inflections"

module ActiveTree
  class RootQuery
    def initialize(model_name, query_str)
      @model_name = model_name.strip
      @query_str = query_str.strip
    end

    def result
      @result ||= begin
        validate!
        klass = resolve_model
        relation = build_base_relation(klass)

        if numeric?
          execute_id_query(relation)
        else
          execute_dsl_query(relation)
        end
      end
    end

    def as_tree_node
      if result[:record]
        RecordNode.new(record: result[:record])
      elsif result[:relation]
        QueryResultsNode.new(
          relation: result[:relation],
          query_description: result[:description]
        )
      end
    end

    private

    def validate!
      raise ArgumentError, "Model class is required" if @model_name.empty?
      raise ArgumentError, "Query is required" if @query_str.empty?
    end

    def resolve_model
      @model_name.constantize
    rescue NameError
      raise ArgumentError, "Model '#{@model_name}' not found"
    end

    def build_base_relation(klass)
      relation = klass.unscoped
      relation = relation.merge(ActiveTree.config.global_scope) if ActiveTree.config.global_scope
      relation
    end

    def numeric?
      @query_str.match?(/\A\d+\z/)
    end

    def execute_id_query(relation)
      record = relation.find_by(id: @query_str.to_i)
      raise ArgumentError, "#{@model_name} with id #{@query_str} not found" unless record

      { record: record }
    end

    def execute_dsl_query(relation)
      result_relation = relation.instance_eval(@query_str)
      peek = result_relation.limit(2).to_a

      raise ArgumentError, "No results for #{@model_name}.#{@query_str}" if peek.empty?

      if peek.size == 1
        { record: peek.first }
      else
        { relation: relation.instance_eval(@query_str), description: "#{@model_name}.#{@query_str}" }
      end
    end
  end
end
