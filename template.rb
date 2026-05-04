# frozen_string_literal: true

# Rails application template for brindu/rails-starter.
#
# Usage:
#
#   rails new myapp \
#     --database=postgresql \
#     --skip-test \
#     --skip-jbuilder \
#     --skip-javascript \
#     -m https://raw.githubusercontent.com/brindu/rails-starter/main/template.rb
#
# See https://github.com/brindu/rails-starter#readme

require "fileutils"
require "tmpdir"

STARTER_REPO = "https://github.com/brindu/rails-starter.git"
STARTER_BRANCH = "main"

# Files copied verbatim from rails-starter into the new app.
OVERLAY_FILES = %w[
  Gemfile
  package.json
  vite.config.ts
  Procfile.dev
  .rspec
  .standard.yml
  .ruby-version
  .gitattributes
  AGENTS.MD
  app/controllers/application_controller.rb
  app/forms/application_form.rb
  app/models/application_query.rb
  bin/ci
  bin/dev
  config/ci.rb
  config/configs/application_config.rb
  spec/spec_helper.rb
  spec/rails_helper.rb
  .github/workflows/ci.yml
  .github/dependabot.yml
]

# Whole directories copied recursively.
OVERLAY_DIRS = %w[app/frontend]

# Files copied then app-name placeholders rewritten.
RENAME_FILES = %w[
  app/views/layouts/application.html.erb
  app/views/pwa/manifest.json.erb
]

# === Verify environment ===

raise Thor::Error.new("rails-starter requires Rails 8.1+; got #{Rails::VERSION::STRING}") if Rails::VERSION::STRING < "8.1"
raise Thor::Error.new("rails-starter expects --database=postgresql") unless options[:database] == "postgresql"
raise Thor::Error.new("rails-starter expects --skip-javascript") unless options[:skip_javascript]
raise Thor::Error.new("rails-starter expects --skip-test") unless options[:skip_test]

# === Clone rails-starter into a temp dir ===

starter_dir = Dir.mktmpdir("rails-starter-")
say_status :clone, "rails-starter into #{starter_dir}", :green
unless system("git clone --depth 1 --branch #{STARTER_BRANCH} #{STARTER_REPO} #{starter_dir}", out: File::NULL, err: File::NULL)
  raise Thor::Error.new("git clone of rails-starter failed")
end

# === Overlay files ===

OVERLAY_FILES.each do |relative_path|
  src = File.join(starter_dir, relative_path)
  dst = File.join(destination_root, relative_path)
  FileUtils.mkdir_p(File.dirname(dst))
  FileUtils.cp(src, dst)
  say_status :overlay, relative_path
end

OVERLAY_DIRS.each do |relative_path|
  src = File.join(starter_dir, relative_path)
  dst = File.join(destination_root, relative_path)
  FileUtils.rm_rf(dst)
  FileUtils.mkdir_p(File.dirname(dst))
  FileUtils.cp_r(src, dst)
  say_status :overlay, "#{relative_path}/"
end

RENAME_FILES.each do |relative_path|
  src = File.join(starter_dir, relative_path)
  dst = File.join(destination_root, relative_path)
  FileUtils.mkdir_p(File.dirname(dst))
  FileUtils.cp(src, dst)
  contents = File.read(dst)
  contents.gsub!("Rails Starter", app_name.titleize)
  contents.gsub!("rails_starter", app_name)
  File.write(dst, contents)
  say_status :rename, relative_path
end

# CLAUDE.md is a symlink to AGENTS.MD in the gold copy; recreate it.
inside(destination_root) do
  File.symlink("AGENTS.MD", "CLAUDE.md") unless File.exist?("CLAUDE.md")
end

# === Inject minimal config/application.rb customizations ===

application <<-'RUBY'
    config.generators.system_tests = nil
    config.autoload_lib(ignore: %w[assets tasks])
RUBY

# === Post-bundle setup ===

after_bundle do
  say_status :bundlebun, "wiring bin/bun", :green
  run "bundle binstub bundlebun --path bin/bun" unless File.exist?("bin/bun")
  run "bin/bun install"

  say_status :solid, "installing solid_queue / solid_cache / solid_cable", :green
  rails_command "solid_queue:install"
  rails_command "solid_cache:install"
  rails_command "solid_cable:install"

  say_status :db, "creating and migrating database", :green
  rails_command "db:prepare"

  say ""
  say "rails-starter applied successfully.", :green
  say ""
  say "Next:"
  say "  cd #{app_name}"
  say "  bin/dev"
  say ""
end
