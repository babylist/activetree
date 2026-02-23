# ActiveTree

A tree-based admin interface for ActiveRecord, built as a Ruby gem. Currently a split-pane TUI rendered with `tty-box`, `tty-screen`, and `pastel`; planned evolution into a mountable Rails Engine.

## Naming

- **Module:** `ActiveTree` (capital T) — matches Rails conventions (`ActiveRecord`, `ActiveSupport`)
- **Gem name / file paths:** `activetree` (lowercase, no separator) — per RubyGems convention
- Never use `Activetree` (that's what `bundle gem` scaffolds, and we renamed it)

## Architecture

**Runtime architecture:** CLI → TreeState → Renderer loop. TreeState owns a tree of nodes (`TreeNode` base → `RecordNode`, `AssociationGroupNode`, `LoadMoreNode`). The `ActiveTree::Model` concern provides per-model DSL (`tree_fields`, `tree_children`, `tree_label`). InputHandler reads raw keypresses; Renderer composes a full-screen frame each tick using two side-by-side `TTY::Box.frame` calls (tree pane + detail pane) with absolute positioning, plus a cursor-positioned footer. Screen is cleared (`\e[H\e[J`) before each frame to prevent stale content.

**Engine upgrade path:** The Railtie is designed to swap its superclass to `Rails::Engine`, add `isolate_namespace`, and gain `config/routes.rb` + `app/` directories. Existing initializer and rake blocks transfer unchanged.

## Code style

- Ruby >= 3.1, double-quoted strings everywhere
- RuboCop with `NewCops: enable`, `Style/Documentation` disabled
- `frozen_string_literal: true` in every `.rb` file
- RSpec for tests (`bundle exec rspec`), RuboCop for linting (`bundle exec rubocop`)

## Key conventions

- `spec.files` uses `git ls-files` — new files must be git-tracked before `gem build` will include them
- Model discovery uses `config.after_initialize` (not `initializer`) because models aren't fully loaded during Rails initialization in development
- `Gemfile.lock` is committed (Bundler recommends tracking it for gems and apps alike)
- Several tty-* gems (`tty-table`, `tty-tree`, `tty-prompt`, `tty-cursor`) remain in the gemspec but are not currently imported — `pastel` is used directly but only declared transitively. Reconcile before publishing.

## Dependencies

Runtime: `activerecord >= 7.0`, `railties >= 7.0`, `tty-box`, `tty-screen`, `pastel`
Dev: `rspec`, `rubocop`, `rake`, `irb`

## Commands

```bash
bin/setup              # Install dependencies
bundle exec rspec      # Run tests
bundle exec rubocop    # Lint
ruby -Ilib exe/activetree  # Run TUI standalone (outside bundler)
bundle exec activetree     # Run TUI via bundler
```

## Repository

GitHub org is `babylist` — https://github.com/babylist/activetree
