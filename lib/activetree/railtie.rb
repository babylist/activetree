# frozen_string_literal: true

require "activetree"

module ActiveTree
  class Railtie < Rails::Railtie
    config.activetree = ActiveTree.config

    rake_tasks do
      namespace :activetree do
        desc "Launch the ActiveTree TUI — usage: rake activetree:tree[Model,id]"
        task :tree, %i[model id] => :environment do |_t, args|
          ActiveTree::CLI.start([args[:model], args[:id]].compact)
        end
      end
    end

    config.after_initialize do
      # Placeholder for future model warm-up.
      # Models aren't fully loaded during initialization in development,
      # so discovery must happen lazily or after eager_load.
    end
  end
end
