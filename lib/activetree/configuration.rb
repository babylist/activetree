# frozen_string_literal: true

module ActiveTree
  class Configuration
    attr_accessor :excluded_models, :max_depth

    def initialize
      @excluded_models = []
      @max_depth = 3
    end
  end
end
