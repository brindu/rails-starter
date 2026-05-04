# AGENTS.md: Rails Code Generation Standards

This document guides AI code generation for this Rails application. It's designed so anyone using Claude, GitHub Copilot, or other AI tools can produce maintainable Rails code without needing a senior engineer to refactor everything.

**Core Principle:** Generated code should be so simple and clear that reading it feels like reading well-written documentation. Elegant. Self-explanatory.

Component-specific guidelines live under `.claude/rules/` and are scoped to the files they apply to via frontmatter `globs`. Load the matching rule before working on a layer:

| Rule file | Loads when working on |
|---|---|
| `.claude/rules/models.md` | `app/models/**/*.rb` |
| `.claude/rules/controllers.md` | `app/controllers/**/*.rb` |
| `.claude/rules/migrations.md` | `db/migrate/**/*.rb`, `db/schema.rb` |
| `.claude/rules/jobs.md` | `app/jobs/**/*.rb` |
| `.claude/rules/configs.md` | `config/configs/**/*.rb`, initializers |
| `.claude/rules/forms.md` | `app/forms/**/*.rb` |
| `.claude/rules/queries.md` | `app/models/**/*_query.rb` |
| `.claude/rules/views.md` | `app/views/**`, `app/components/**`, `app/frontend/**`, `app/helpers/**` |
| `.claude/rules/tests.md` | `spec/**/*.rb` |
| `.claude/rules/routing.md` | `config/routes.rb` |

---

## Project Overview

We build Rails applications that prioritize **simplicity, clarity, and maintainability**. We trust Rails conventions rather than fighting them. We name things after business domains, not technical patterns. We avoid over-architecture.

Generated code should:
- Follow Rails conventions (not fight the framework)
- Use domain language (Participant, not User; Cloud, not GeneratedImage)
- Keep logic at the right layer (models handle data, controllers handle HTTP, jobs coordinate workflows)
- Be readable without comments
- Normalize data properly (separate concerns into tables, not columns)

---

## Technology Stack & Gems

**Only use these gems.** If you want to add something not listed, ask in a clarifying comment.

### Core Rails & Server
- `rails` (latest stable)
- `puma` (default)
- `propshaft` (static asset pipeline — coexists with Vite)

### Database & Data
- `activerecord` (included)
- `pg` (PostgreSQL)
- `store_model` (type-safe JSON columns, when needed)

### Frontend
- `turbo-rails` (Turbo Drive, Frames, Streams)
- `@hotwired/stimulus` + `stimulus-vite-helpers` (Stimulus via npm, auto-registered controllers)
- `tailwindcss` + `@tailwindcss/vite` (Tailwind CSS v4 via Vite plugin, no PostCSS needed)
- `view_component` (reusable UI components)
- `rails_vite` + `rails-vite-plugin` (Vite integration with no proxy — coexists with Propshaft via a stub file; provides `vite_tags` helper)
- `bundlebun` (Bun runtime as a gem — no system Node.js needed, use `bin/bun` for npm commands)
- Don't use: `hotwire-rails` (deprecated), `stimulus-rails` (not needed with Vite), `vite_rails` / `vite_ruby` (replaced by `rails_vite` — no Rack proxy, no shared config)

### Jobs & Background Work
- `solid_queue` (default)

### Authentication & Authorization
- built-in authentication (generator)
- `omniauth` (for OAuth)
- `action_policy` (for complex authorization)

### Configuration
- `anyway_config` (type-safe configuration from environment)
- Don't use: Rails credentials, ENV variables directly

### Testing
- `rspec-rails` (not minitest)
- `factory_bot_rails` (test data)
- `faker` (realistic fake data)
- `test_prof` (for faster tests)
- `simplecov` + `simplecov-json` (code coverage — generates HTML + JSON in `coverage/`)

### Code Quality
- `standard` (Ruby linting—replaces Rubocop)
- `prettier` (JavaScript formatting, if you have JS)
- `herb` (ERB template parser gem) + `@herb-tools/linter` (ERB linting via npm) + `@herb-tools/formatter` (ERB formatting via npm)
- `qlty` (CLI tool — code smells, maintainability metrics, security scanning via gitleaks/osv-scanner/trivy). Config: `.qlty/qlty.toml`

### IDs & Slugs
- `nanoid` (short, URL-safe IDs)
- `friendly_id` (SEO-friendly slugs)

### HTTP & API
- `httparty` (clean, readable HTTP requests)
- Don't use: Faraday, RestClient

### Admin
- `avo` (modern Rails admin panel, if you need it)

### Error Tracking
- `sentry-rails` (error reporting—optional)

**Don't use:**
- Service objects (services/)
- Context objects (contexts/)
- Use case / operation / interactor gems
- Custom authentication modules
- Concerns for business logic
- Devise
- CanCanCan
- ActiveAdmin
- Complex state machine gems (use enums)
- Virtus, Literal, dry-types, reform (use plain models)
- `vite_rails` / `vite_ruby` (replaced by `rails_vite`)

---

## File Structure & Organization

### Folder Layout

```
app/
├── models/
│   ├── application_record.rb
│   ├── participant.rb
│   ├── cloud.rb
│   ├── cloud/
│   │   ├── card_generator.rb      # Namespaced under model
│   │   ├── nsfw_detector.rb
│   │   └── query.rb
│   ├── invitation.rb
│   ├── invitation/
│   │   └── mailer.rb
│   └── application_query.rb        # Base class for queries
├── controllers/
│   ├── application_controller.rb
│   ├── clouds_controller.rb
│   ├── participant/                # Namespace for scoped routes
│   │   ├── application_controller.rb
│   │   ├── clouds_controller.rb
│   │   └── homes_controller.rb
│   └── webhooks/
│       └── mandrill_controller.rb
├── jobs/
│   ├── application_job.rb
│   └── cloud_generation_job.rb
├── forms/                          # Only when creating multiple models
│   ├── application_form.rb
│   └── participant_registration_form.rb
├── mailers/
│   ├── application_mailer.rb
│   └── invitation_mailer.rb
├── policies/                       # Only when complex authorization is needed
│   ├── application_policy.rb
│   └── cloud_policy.rb
├── views/
│   ├── clouds/
│   ├── participant/
│   │   ├── clouds/
│   │   └── homes/
│   ├── layouts/
│   └── components/                 # ViewComponent components
│       └── cloud_card.html.erb
└── frontend/                       # Vite source (bundled via rails_vite)
    ├── entrypoints/                # application.js (imports Turbo + Stimulus), application.css
    ├── controllers/                # Stimulus controllers (auto-registered via stimulus-vite-helpers)
    └── styles/                     # additional CSS

config/
├── configs/                        # anyway_config classes
│   ├── application_config.rb
│   ├── gemini_config.rb
│   ├── smtp_config.rb
│   └── app_config.rb
├── database.yml
├── routes.rb
└── puma.rb

db/
├── migrate/
├── seeds.rb
└── schema.rb

spec/
├── models/
├── requests/                       # Controller tests
├── system/                         # Full-stack browser tests
├── factories/
├── support/
└── spec_helper.rb
```

**Critical rules:**
- No `app/services/` folder
- No `app/contexts/` folder
- No `app/operations/` folder
- Complex operations go in namespaced model classes: `Cloud::CardGenerator`
- Controllers are namespaced for authentication/scoping: `Participant::CloudsController`

---

## Common Patterns & Anti-Patterns

### Pattern: Guard Clauses Over Nested Conditionals

**Bad:**
```ruby
def create
  if admin?
    if params[:valid]
      if check_limit
        create_object
      end
    end
  end
end
```

**Good:**
```ruby
def create
  return head 401 unless admin?
  return head 422 unless params[:valid]
  return head 429 unless check_limit
  create_object
end
```

### Pattern: Delegation Over Inheritance for Small Helpers

**Bad:**
```ruby
module EmailHelper
  def participant_email
    "#{@participant.slug}@example.com"
  end
end

class CloudsController < ApplicationController
  include EmailHelper
end
```

**Good:**
```ruby
class CloudsController < ApplicationController
  def email_address
    @participant.participant_email  # Delegate to model
  end
end

class Participant
  def participant_email
    "#{slug}@example.com"
  end
end
```

### Anti-Pattern: Service Objects

**Don't create `app/services/`:**
```ruby
# Bad
class ImageGenerationService
  def initialize(cloud)
    @cloud = cloud
  end

  def call
    # Logic here
  end
end
```

**Do this instead:**
- **Model method:** `cloud.generate_image!`
- **Namespaced class:** `Cloud::CardGenerator.new(cloud).generate`
- **Job:** `CloudGenerationJob.perform_later(cloud)`

### Anti-Pattern: Result Objects

**Don't use:**
```ruby
Result = Struct.new(:success?, :data, :error, keyword_init: true)

generator.call  # => Result.new(success?: true, data: io, error: nil)
```

**Do this instead:**
```ruby
generator.generate  # => returns IO, raises on error
```

Return simple values. Raise exceptions. Let the caller decide.

### Anti-Pattern: Passing Around Hashes

**Bad:**
```ruby
def create_cloud(params)
  { state: "generating", id: cloud.id, user_id: cloud.participant_id }
end

result = create_cloud(name: "test")
puts result[:state]
```

**Good:**
```ruby
def create_cloud(params)
  Participant.create!(**params)
end

cloud = create_cloud(name: "test")
puts cloud.state
```

Return objects, not hashes. Type-safe and IDE-friendly.

---

## Development Workflow

### Generators: What to Use

```bash
# Generate models with associations
rails generate model Cloud participant:references state:enum

# Generate controllers with actions
rails generate controller Participant::Clouds show create

# Generate jobs
rails generate job CloudGeneration

# Generate migrations
rails generate migration AddPickedToClouds picked:boolean
```

### What NOT to Generate

Don't use Rails generators for:
- Service objects (don't generate these)
- Scaffolding (too much boilerplate)
- Full CRUD (customize manually)

### Standard Ruby Linting

```bash
# Check style
bundle exec standardrb

# Fix automatically
bundle exec standardrb --fix
```

### ERB Template Linting & Formatting (Herb)

```bash
# Lint all ERB templates
bin/bun x @herb-tools/linter

# Auto-fix safe lint issues
bin/bun x @herb-tools/linter --fix

# Check formatting (CI mode — exits non-zero if unformatted)
bin/bun x herb-format --check .

# Auto-format all templates
bin/bun x herb-format .
```

### Qlty (Code Smells, Metrics & Security)

```bash
# Run all checks (security, infrastructure linting)
qlty check --all

# Code smell detection (duplication, complexity)
qlty smells --all

# Maintainability metrics
qlty metrics --all
```

---

## Summary: The Checklist

Before writing/generating code, ask:

- [ ] Is this named after a business domain concept (not technical)?
- [ ] Is the model organized in the right order (gems → associations → enums → validations → scopes)?
- [ ] Are states in enums, not string columns?
- [ ] Is the controller action under 10 lines, with preconditions in `before_action`?
- [ ] Is complex logic extracted to namespaced model classes (e.g., `Cloud::CardGenerator`)?
- [ ] Is the database normalized (one concern per table)?
- [ ] Are foreign keys and constraints added?
- [ ] Are counter caches used for has_many?
- [ ] Are workflows in jobs with `ActiveJob::Continuable`?
- [ ] Is configuration via `anyway_config`, not ENV?
- [ ] Are tests in RSpec, not minitest?
- [ ] Are views simple (scopes/associations, no complex logic)?

If yes to all: your code is ready to ship.

---

## Quick Reference

| Pattern | Location | When |
|---------|----------|------|
| Model method | `Cloud#ready_to_generate?` | Simple query or check |
| Namespaced class | `Cloud::CardGenerator` | Complex operation (>15 lines) |
| Scope | `Cloud.generated` | Reusable query |
| Job | `CloudGenerationJob` | Async workflow or steps |
| Form Object | `ParticipantRegistrationForm` | Multi-model create/update |
| Query Object | `Participant::PendingQuery` | Complex query |
| Controller action | `Participant::CloudsController#create` | HTTP handling only |
| View component | `CloudCardComponent` | Reusable UI |
| Config class | `GeminiConfig` | Configuration |

| Anti-Pattern | Why | Alternative |
|---|---|---|
| Service object | Unnecessary abstraction | Namespaced model class |
| Result object | Over-engineered | Return value or raise |
| Concern for logic | Magic, hard to trace | Inheritance or delegation |
| ENV variables | Untyped, scattered | anyway_config |
| String state | Type-unsafe | Enum |
| Denormalized schema | Harder to query/extend | Normalized with FK + constraints |
| Fat models | Hard to maintain | Extract to namespaced classes |
| Fat controllers | Hard to test | Thin controller + model method |
| Complex conditionals | Hard to read | Guard clauses |
| Inline precondition guards | Bloats actions, not reusable | `before_action` hooks |
