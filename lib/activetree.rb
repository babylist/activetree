# frozen_string_literal: true

require_relative "activetree/version"

module ActiveTree
  class Error < StandardError; end

  autoload :CLI, "activetree/cli"
  autoload :TreeBuilder, "activetree/tree_builder"
  autoload :Configuration, "activetree/configuration"

  class << self
    def config
      @config ||= Configuration.new
    end

    def configure
      yield config
    end
  end
end

require "activetree/railtie" if defined?(Rails::Railtie)
