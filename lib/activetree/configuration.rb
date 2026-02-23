# frozen_string_literal: true

require_relative "configuration/model"

module ActiveTree
  class Configuration
    attr_accessor :excluded_models, :max_depth, :default_limit

    def initialize
      @excluded_models = []
      @max_depth = 3
      @default_limit = 25
      @model_configurations = {}
    end

    def model_configuration(model_class)
      @model_configurations[model_class] ||= Configuration::Model.new(model_class)
    end
  end
end
