# frozen_string_literal: true

module ActiveTree
  class Configuration
    class Model
      class Field
        attr_reader :name

        def initialize(name, label: nil)
          @name = name
          @label = label || name
        end

        def label
          @label&.to_s
        end
      end
    end
  end
end
