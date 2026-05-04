---
description: Configuration via anyway_config — type-safe, singleton, never use ENV or Rails credentials directly
globs:
  - config/configs/**/*.rb
  - config/initializers/**/*.rb
---

# Configuration Management

## Use anyway_config for Type-Safe Configuration

**Pattern:**
```ruby
# config/configs/application_config.rb
class ApplicationConfig < Anyway::Config
  class << self
    delegate_missing_to :instance

    private

    def instance
      @instance ||= new
    end
  end
end

# config/configs/gemini_config.rb
class GeminiConfig < ApplicationConfig
  attr_config :api_key
end

# config/configs/app_config.rb
class AppConfig < ApplicationConfig
  attr_config :host, :port,
    admin_username: "admin",
    admin_password: "pass"

  def ssl?
    port == 443
  end

  def asset_host
    super || begin
      proto = ssl? ? "https://" : "http://"
      "#{proto}#{host}"
    end
  end
end
```

**Usage:**
```ruby
GeminiConfig.api_key
AppConfig.host
AppConfig.ssl?
```

**Environment variables map automatically:**
```bash
GEMINI_API_KEY=xxx          # → GeminiConfig.api_key
APP_HOST=example.com        # → AppConfig.host
APP_PORT=443                # → AppConfig.port
```

**Why this approach:**
- Type-safe (validates on load)
- Singleton pattern (access anywhere)
- Organized in `config/configs/`
- Can add helper methods (ssl?, configured?)
- Environment-specific (development, test, production)

## Never use Rails credentials or ENV directly

**Bad:**
```ruby
api_key = ENV["GEMINI_API_KEY"]  # Error-prone, untyped

ENV.fetch("API_KEY", "default")  # Works, but no validation
```

**Good:**
```ruby
api_key = GeminiConfig.api_key  # Type-safe, organized, testable
```

## Environment Variables (mapped via anyway_config)

```bash
# .env (development/test)
GEMINI_API_KEY=test-key
APP_HOST=localhost:3000
APP_PORT=3000

# .env.production
GEMINI_API_KEY=production-key
APP_HOST=example.com
APP_PORT=443
```

## Error Tracking

```ruby
# Sentry (optional but recommended)
Sentry.init do |config|
  config.dsn = "https://xxxx@xxxx.ingest.sentry.io/xxxx"
  config.traces_sample_rate = 1.0
end

# In jobs/code
rescue => err
  Rails.error.report(err, handled: true)
end
```
