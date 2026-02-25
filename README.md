# ActiveTree

An interactive tree-based admin interface for ActiveRecord. ActiveTree renders a persistent split-pane TUI (terminal UI) for browsing records, their associations, and field values.

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
# Within a Rails app

bin/rails "activetree:tree[User,42]"
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

Singular forms accept keyword options:

```ruby
class Order < ApplicationRecord
  include ActiveTree::Model

  tree_field :id
  tree_field :status, label: "Order Status"
  tree_child :line_items, label: "Items"
  tree_child :shipments
end
```

The plural forms also accept inline option hashes to customize individual entries:

```ruby
class User < ApplicationRecord
  include ActiveTree::Model

  tree_fields :id, :email, { name: { label: "Full Name" } }, :created_at
  tree_children :orders, { shipments: { label: "User Shipments" } }
end
```

### Scoping Child Relations

You can pass an ActiveRecord scope to `tree_child` to filter which records appear in the tree. The scope proc is evaluated via `instance_exec` on the association relation, so named scopes and query methods work naturally:

```ruby
class User < ApplicationRecord
  include ActiveTree::Model

  tree_child :comments, -> { approved }, label: "Approved Comments"
  tree_child :orders, -> { where(status: "active") }
end
```

The `tree_children` hash form supports `scope:` as well:

```ruby
class User < ApplicationRecord
  include ActiveTree::Model

  tree_children :orders, { comments: { scope: -> { approved }, label: "Approved" } }
end
```

Scopes work for both collection (`has_many`) and singular (`has_one`, `belongs_to`) associations. The scope is merged with the existing association relation — it never replaces it.

| Method | Default | Description |
|-----------|---------|-------------|
| `tree_fields` | `:id` only | Fields shown in the detail pane (batch) |
| `tree_field` | — | Add a single field with keyword options (`label:`) |
| `tree_children` | None | Associations expandable as tree children (batch) |
| `tree_child` | — | Add a single child with options (`label:`, positional scope proc) |
| `tree_label` | `-> (record) { "#{record.class.name} #{record.id}" }` | Custom label block for tree nodes and detail pane |

Models **without** the mixin still appear in the tree if referenced as children of another model, using the defaults above.

### Centralized Configuration via DSL

ActiveTree can also be configured centrally with a DSL (e.g. in an initializer). This is especially useful for third-party models or keeping tree config separate from your models:

```ruby
# config/initializers/activetree.rb
ActiveTree.configure do
  max_depth 5
  default_limit 50

  model "User" do
    fields :id, :email, :name, :created_at
    children :orders, :profile
    label { |record| "#{record.name} (#{record.email})" }
  end

  model "Order" do
    field :id
    field :status, label: "Order Status"
    child :line_items, label: "Items"
    child :shipments
  end
end
```

Model names are passed as strings because classes may not be loaded when the initializer runs. The DSL methods mirror the `ActiveTree::Model` concern without the `tree_` prefix:

| DSL Method | Equivalent Concern Method | Description |
|-----------|--------------------------|-------------|
| `field :name, label: "..."` | `tree_field` | Add a single field |
| `fields :id, :email, ...` | `tree_fields` | Add multiple fields |
| `child :orders, scope, label: "..."` | `tree_child` | Add a single child (optional scope proc + label) |
| `children :orders, :shipments` | `tree_children` | Add multiple children |
| `label { \|r\| ... }` | `tree_label` | Custom label block |

#### Merging with the Model Concern

Both configuration styles write to the same underlying config. If a model is configured in an initializer _and_ includes `ActiveTree::Model`, the results merge — fields and children accumulate, and last-write-wins for any given name:

```ruby
# initializer
ActiveTree.configure do
  model "User" do
    field :id
    field :name, label: "First"
  end
end

# model
class User < ApplicationRecord
  include ActiveTree::Model
  tree_field :email
  tree_field :name, label: "Full Name"  # overwrites initializer's label
end
```

### Global Options

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
