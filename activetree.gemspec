# frozen_string_literal: true

require_relative "lib/activetree/version"

Gem::Specification.new do |spec|
  spec.name = "activetree"
  spec.version = ActiveTree::VERSION
  spec.authors = ["Alex Ford"]
  spec.email = ["alex.ford@babylist.com"]

  spec.summary = "A tree-based admin interface for Rails applications"
  spec.homepage = "https://github.com/babylist/activetree"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.metadata["rubygems_mfa_required"] = "true"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/babylist/activetree"
  spec.metadata["changelog_uri"] = "https://github.com/babylist/activetree/blob/main/CHANGELOG.md"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", ">= 7.0"
  spec.add_dependency "railties", ">= 7.0"
  spec.add_dependency "tty-box", "~> 0.7"
  spec.add_dependency "tty-cursor", "~> 0.7"
  spec.add_dependency "tty-prompt", "~> 0.23"
  spec.add_dependency "tty-screen", "~> 0.8"
  spec.add_dependency "tty-table", "~> 0.12"
  spec.add_dependency "tty-tree", "~> 0.4"
end
