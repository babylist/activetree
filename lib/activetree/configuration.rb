# frozen_string_literal: true

module ActiveTree
  class Configuration
    attr_accessor :excluded_models, :max_depth, :default_limit

    def initialize
      @excluded_models = []
      @max_depth = 3
      @default_limit = 25
    end
  end
end
