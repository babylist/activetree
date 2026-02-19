# frozen_string_literal: true

require "tty-tree"
require "tty-prompt"
require "tty-box"
require "tty-screen"
require "tty-cursor"

module ActiveTree
  class CLI
    def self.start
      new.run
    end

    def run
      cursor = TTY::Cursor
      print cursor.clear_screen
      print cursor.move_to(0, 0)

      puts header_box
      puts ""
      puts TTY::Tree.new(tree_data).render
    end

    private

    def header_box
      width = [TTY::Screen.width, 60].min

      TTY::Box.frame(
        width: width,
        padding: [0, 1],
        title: { top_left: " ActiveTree " },
        border: :light
      ) do
        "Tree-based admin interface v#{ActiveTree::VERSION}"
      end
    end

    def tree_data
      if defined?(ActiveRecord::Base)
        ActiveTree::TreeBuilder.new.to_tree_data
      else
        placeholder_tree
      end
    end

    def placeholder_tree
      {
        "ActiveTree (no ActiveRecord connection)" => [
          { "Configure ActiveRecord to see your models" => [] },
          { "Run within a Rails app or require activerecord" => [] }
        ]
      }
    end
  end
end
