source "https://rubygems.org"

gem "rails", "~> 8.1.3"

# Asset pipeline — Propshaft serves static assets; Vite (rails_vite) bundles JS/CSS.
gem "propshaft"

# Database & server
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"

# Hotwire
gem "turbo-rails"
# Stimulus is loaded via npm + stimulus-vite-helpers (no stimulus-rails gem).

# Vite integration without a Rack proxy [https://github.com/skryukov/rails_vite]
gem "rails_vite"

# Bun runtime as a gem — provides bin/bun, no system Node.js needed
gem "bundlebun"

# UI components
gem "view_component"

# Type-safe JSON columns (when needed)
gem "store_model"

# Register after_commit callbacks from outside ActiveRecord (used by ApplicationForm)
gem "after_commit_everywhere"

# Type-safe configuration from environment
gem "anyway_config"

# IDs & slugs
gem "friendly_id"
gem "nanoid"

# HTTP client
gem "httparty"

# Background jobs / cache / cable — database-backed adapters
gem "solid_queue"
gem "solid_cache"
gem "solid_cable"

# Active Storage variants
gem "image_processing", "~> 1.2"

# Reduces boot times through caching
gem "bootsnap", require: false

# Deployment
gem "kamal", require: false

# HTTP asset caching/compression for Puma
gem "thruster", require: false

gem "tzinfo-data", platforms: %i[windows jruby]

group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"

  # RSpec stack
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
  gem "test-prof"

  # Coverage
  gem "simplecov", require: false
  gem "simplecov-json", require: false

  # Linting (replaces rubocop)
  gem "standard", ">= 1.35.1", require: false

  # Security
  gem "bundler-audit", require: false
  gem "brakeman", require: false
end

group :development do
  gem "web-console"
end
