# frozen_string_literal: true

module ActiveTree
  class Configuration
    class Dsl
      def initialize(configuration)
        @configuration = configuration
      end

      def max_depth(value)
        @configuration.max_depth = value
      end

      def default_limit(value)
        @configuration.default_limit = value
      end

      def model(name, &block)
        model_config = @configuration.model_configuration(name)
        ModelDsl.new(model_config).instance_eval(&block) if block
        model_config
      end
    end
  end
end
