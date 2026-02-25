# frozen_string_literal: true

require_relative "configuration/model"
require_relative "configuration/dsl"
require_relative "configuration/model_dsl"

module ActiveTree
  class Configuration
    attr_accessor :max_depth, :default_limit, :global_scope

    def initialize
      @max_depth = 3
      @default_limit = 25
      @model_configurations = {}
    end

    def model_configuration(model_key)
      key = normalize_model_key(model_key)
      @model_configurations[key] ||= Configuration::Model.new(key)
    end

    private

    def normalize_model_key(key)
      case key
      when String
        key
      when Class
        key.name || "__anonymous_#{key.object_id}"
      else
        key.to_s
      end
    end
  end
end
