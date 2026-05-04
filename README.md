# rails-starter

Opinionated Rails 8 application starter. Lives as both a working Rails app
(the gold copy) and a `template.rb` script you point `rails new` at.

## What's bundled

- **Frontend** — Vite + Bun (via `bundlebun`, no system Node), Tailwind v4
  (via `@tailwindcss/vite`, no PostCSS), Hotwire (Turbo + Stimulus via npm),
  ViewComponent
- **Backend** — Rails 8.1, PostgreSQL, Solid Queue / Cache / Cable,
  `anyway_config` for typed configuration, `friendly_id`, `nanoid`,
  `httparty`, `store_model`, `after_commit_everywhere`
- **Base classes** — `ApplicationQuery`, `ApplicationForm` already wired
- **Testing** — RSpec, FactoryBot, Faker, test-prof, SimpleCov (HTML + JSON)
- **Quality** — Standard (Ruby), Herb (ERB lint + format), Brakeman,
  bundler-audit, qlty
- **Ops** — Kamal, Thruster, Dockerfile, GitHub Actions CI, Dependabot
- **Conventions** — `AGENTS.MD` / `CLAUDE.md` documenting the codebase
  patterns AI tools should follow

## Using it for a new project

```sh
rails new myapp \
  --database=postgresql \
  --skip-test \
  --skip-jbuilder \
  --skip-hotwire \
  --skip-asset-pipeline \
  -m https://raw.githubusercontent.com/brindu/rails-starter/main/template.rb
```

The `template.rb` script clones this repo and overlays its files onto the
freshly generated app, then runs `bundle`, `bin/bun install`, and `db:setup`.

## Running this repo directly

```sh
bin/setup
bin/dev
```

The starter itself boots as a working Rails app — useful for testing changes
to the gold copy before they propagate to consumers.
