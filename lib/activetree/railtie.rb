# frozen_string_literal: true

require "activetree"

module ActiveTree
  class Railtie < Rails::Railtie
    config.activetree = ActiveTree.config

    rake_tasks do
      namespace :activetree do
        desc "Launch the ActiveTree TUI"
        task tree: :environment do
          ActiveTree::CLI.start
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
