# ActiveTree 🌳

A tree-based admin interface for ActiveRecord. ActiveTree renders an interactive TUI (terminal UI) showing model hierarchies, associations, and column types.

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

### Standalone (TUI)

Run the executable directly to launch the terminal interface:

```bash
bundle exec activetree
```

Without an ActiveRecord connection, a placeholder tree is displayed. Connect to a Rails app to see your actual models.

### Within a Rails app

ActiveTree ships with a Railtie that registers automatically. Launch the TUI via rake:

```bash
bin/rails activetree:tree
```

### Configuration

```ruby
ActiveTree.configure do |config|
  config.excluded_models = ["ApplicationRecord", "ActiveStorage::Blob"]
  config.max_depth = 5
end
```

| Option | Default | Description |
|--------|---------|-------------|
| `excluded_models` | `[]` | Model names to hide from the tree |
| `max_depth` | `3` | Maximum nesting depth for associations |

## Development

```bash
bin/setup            # Install dependencies
bundle exec rspec    # Run tests
bundle exec rubocop  # Lint
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/alexford/activetree.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
