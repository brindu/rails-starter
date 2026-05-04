---
description: View, frontend, and styling conventions — Hotwire (Turbo + Stimulus), Tailwind v4, ViewComponent, simple views
globs:
  - app/views/**
  - app/components/**
  - app/frontend/**
  - app/helpers/**/*.rb
---

# View & Frontend Patterns

## Use Hotwire: Turbo + Stimulus

**Don't build SPAs.** Use Hotwire for interactivity.

**Turbo for page updates:**
```erb
<%= turbo_stream_from @cloud %>

<div id="<%= dom_id(@cloud) %>">
  <%= render "cloud", cloud: @cloud %>
</div>
```

```ruby
# In job or controller
cloud.update!(state: :generated)
Turbo::StreamsChannel.broadcast_refresh_to(cloud)
```

**Stimulus for JavaScript sprinkles:**
```erb
<div data-controller="timer">
  <button data-action="timer#start">Start</button>
  <span data-timer-target="display">0:00</span>
</div>
```

```javascript
// app/frontend/controllers/timer_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display"]

  start() {
    // Timer logic
  }
}
```

## Tailwind CSS v4

Tailwind is configured as a Vite plugin (`@tailwindcss/vite`). No PostCSS config or `tailwind.config.js` needed.

**CSS entrypoint:** `app/frontend/entrypoints/application.css`
```css
@import "tailwindcss";
```

**Customizing the theme:** Use `@theme` directives in CSS (not a JS config file):
```css
@import "tailwindcss";

@theme {
  --color-primary: #3b82f6;
  --color-secondary: #64748b;
  --font-display: "Inter", sans-serif;
}
```

**Using Tailwind in views:**
```erb
<div class="flex items-center gap-4 p-6 bg-white rounded-lg shadow">
  <h2 class="text-lg font-semibold text-gray-900"><%= cloud.name %></h2>
  <span class="px-2 py-1 text-sm rounded-full bg-primary text-white"><%= cloud.state %></span>
</div>
```

**Custom component classes** (use `@layer components` sparingly — prefer Tailwind utilities directly):
```css
@layer components {
  .btn {
    @apply px-4 py-2 rounded-lg font-medium transition-colors;
  }
  .btn-primary {
    @apply btn bg-primary text-white hover:bg-primary/90;
  }
}
```

**Don't:**
- Create a `tailwind.config.js` (use `@theme` in CSS instead)
- Create a `postcss.config.js` (the Vite plugin handles everything)
- Over-abstract with `@apply` — use utility classes directly in templates

## Use ViewComponent for Reusable UI

```ruby
# app/components/cloud_card_component.rb
class CloudCardComponent < ViewComponent::Base
  def initialize(cloud)
    @cloud = cloud
  end

  private

  attr_reader :cloud
end
```

```erb
<!-- app/components/cloud_card_component.html.erb -->
<div class="cloud-card" id="<%= dom_id(cloud) %>">
  <h3><%= cloud.name %></h3>
  <p><%= cloud.state %></p>
</div>
```

**Usage in views:**
```erb
<%= render CloudCardComponent.new(cloud) %>
```

## Database Queries from Views

**Good:** Simple associations and scopes
```erb
<% @participant.clouds.recent.each do |cloud| %>
  <%= render "cloud", cloud: %>
<% end %>
```

**Bad:** N+1 queries, complex logic in views
```erb
<!-- DON'T: complex query logic -->
<% @clouds.select { |c| c.participant.premium? && c.state.in?(%w[generated]) } %>
```

**Instead:** Query object or scope
```ruby
# Model
scope :recent, -> { order(created_at: :desc) }

# Controller
@clouds = @participant.clouds.recent

# View
<% @clouds.each do |cloud| %>
  <%= render "cloud", cloud: %>
<% end %>
```
