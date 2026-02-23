# ActiveTree

An interactive tree-based admin interface for ActiveRecord. ActiveTree renders a persistent split-pane TUI (terminal UI) for browsing records, their associations, and field values — like nerdtree for your database.

## Installation

Add to your application's Gemfile:

```ruby
gem "activetree"
```

Then run:

```bash
bundle install
```

## Usage

### Launching the TUI

ActiveTree browses a single root record and its association tree. Pass a model name and ID:

```bash
# Within a Rails app (via rake)
bin/rails activetree:tree[User,42]

# Standalone (with ActiveRecord configured)
bundle exec activetree User 42
```

The TUI opens a full-screen split-pane interface:
- **Left pane** — navigable tree with expand/collapse for associations
- **Right pane** — field/value detail view for the selected record

### Key Bindings

| Key | Action |
|-----|--------|
| `j` / `Down` | Move cursor down |
| `k` / `Up` | Move cursor up |
| `Space` | Expand / collapse node |
| `Enter` | Select record (show details in right pane) |
| `r` | Make selected record the new root |
| `q` | Quit |

### Configuring Models

Include `ActiveTree::Model` in your AR models to control what appears in the TUI:

```ruby
class User < ApplicationRecord
  include ActiveTree::Model

  tree_fields :id, :email, :name, :created_at
  tree_children :orders, :profile
  tree_label { |record| "#{record.name} (#{record.email})" }
end
```

Singular forms accept an optional display label:

```ruby
class Order < ApplicationRecord
  include ActiveTree::Model

  tree_field :id
  tree_field :status, "Order Status"
  tree_child :line_items, "Items"
  tree_child :shipments
end
```

| DSL Method | Default | Description |
|-----------|---------|-------------|
| `tree_fields` | `:id` only | Fields shown in the detail pane (batch) |
| `tree_field` | — | Add a single field with an optional display label |
| `tree_children` | None | Associations expandable as tree children (batch) |
| `tree_child` | — | Add a single child association with an optional display label |
| `tree_label` | `"ClassName #id"` | Custom label block for tree nodes and detail pane |

Models **without** the mixin still appear in the tree — they show only `:id` in the detail pane and have no expandable children.

### Configuration

```ruby
ActiveTree.configure do |config|
  config.max_depth = 5
  config.default_limit = 50
end
```

| Option | Default | Description |
|--------|---------|-------------|
| `max_depth` | `3` | Maximum nesting depth for associations NOT YET IMPLEMENTED |
| `default_limit` | `25` | Max records loaded per has_many expansion (paginated) |

### Pagination

Large `has_many` associations are loaded in pages of `default_limit` records. When more records exist, a `[load more...]` node appears at the bottom of the group. Activate it with `Space` to load the next page.

## Development

```bash
bin/setup            # Install dependencies
bundle exec rspec    # Run tests
bundle exec rubocop  # Lint
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/babylist/activetree.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
