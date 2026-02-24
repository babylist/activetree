# frozen_string_literal: true

module ActiveTree
  class Configuration
    class Model
      class Child
        attr_reader :name, :scope

        def initialize(name, label: nil, scope: nil)
          @name = name
          @label = label || name
          @scope = scope
        end

        def label
          @label&.to_s
        end
      end
    end
  end
end
