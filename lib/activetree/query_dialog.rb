# frozen_string_literal: true

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

    def root_query
      RootQuery.new(fields[0].value, fields[1].value)
    end
  end
end
