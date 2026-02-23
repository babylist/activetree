# frozen_string_literal: true

module ActiveTree
  class Configuration
    class Model
      class Child
        attr_reader :name, :label

        def initialize(name, label = nil)
          @name = name
          @label = label || name
        end
      end
    end
  end
end
