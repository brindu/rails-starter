---
description: Rails routing conventions — RESTful resources, namespaces, scopes for parameter injection
globs:
  - config/routes.rb
---

# Routing

## RESTful Routes with Namespaces

```ruby
Rails.application.routes.draw do
  root "clouds#index"

  # Public routes
  resources :clouds, only: [:index, :show]

  # Participant-scoped routes
  scope "/c/:access_token", as: :participant, module: :participant do
    resource :home, only: [:show]
    resources :clouds
  end

  # Admin namespace
  mount Avo::Engine, at: Avo.configuration.root_path

  # Webhooks
  namespace :webhooks do
    resource :mandrill, only: [:create]
  end
end
```

**Route patterns:**
- RESTful resources (index, show, create, update, delete)
- Namespaces for logical grouping (admin, webhooks, participant)
- Scopes for parameter injection (:access_token available to all routes)
- Conditionally mount tools (dev-only, feature-flagged)
