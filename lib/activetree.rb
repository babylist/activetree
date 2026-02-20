# frozen_string_literal: true

require_relative "activetree/version"

module ActiveTree
  class Error < StandardError; end

  autoload :CLI, "activetree/cli"
  autoload :Configuration, "activetree/configuration"
  autoload :Model, "activetree/model"
  autoload :TreeNode, "activetree/tree_node"
  autoload :RecordNode, "activetree/record_node"
  autoload :AssociationGroupNode, "activetree/association_group_node"
  autoload :LoadMoreNode, "activetree/load_more_node"
  autoload :TreeState, "activetree/tree_state"
  autoload :Renderer, "activetree/renderer"
  autoload :InputHandler, "activetree/input_handler"

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
