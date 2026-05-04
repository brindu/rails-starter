---
description: Rails controller conventions — thin actions, before_action precondition guards, namespacing for scoping, helper methods
globs:
  - app/controllers/**/*.rb
---

# Controller Patterns

## Helper methods

**Declare helper methods on top of controller classes before methods definition.**

```ruby
class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  helper_method :current_account
  helper_method :signed_in?

  private

  def current_account
    @current_account ||= Account.find_by(id: session[:account_id]) if session[:account_id]
  end

  def signed_in?
    current_account.present?
  end

  def require_authentication
    redirect_to root_path, alert: "Please sign in first." unless signed_in?
  end
end
```

## Keep Controllers Extremely Thin

**Target: 5-10 lines per action.** No business logic.

```ruby
class Participant::CloudsController < Participant::ApplicationController
  def new
    redirect_to home_path unless @participant.can_generate_cloud?
  end

  def create
    return head 422 unless @participant.can_generate_cloud?

    blob = ActiveStorage::Blob.find_signed(params[:cloud][:blob_signed_id])
    return head 422 unless blob

    cloud = @participant.clouds.create do
      it.image.attach(blob)
    end

    CloudGenerationJob.perform_later(cloud)

    redirect_to cloud_path(cloud)
  end

  def update
    cloud = @participant.clouds.find(params[:id])
    Cloud.transaction do
      @participant.clouds.update_all(picked: false)
      cloud.update_column(:picked, true)
    end

    redirect_to home_path
  end
end
```

**Action breakdown:**
- Precondition guards in `before_action` hooks (auth, resource loading, cooldowns)
- Simple model operations (create, update)
- Job enqueueing
- Redirect/render

**No:**
- Business logic
- Complex conditionals
- Multiple model operations (use Form Object instead)
- Data transformation

## Use Namespace Controllers for Authentication/Scoping

**Pattern:**
```ruby
# app/controllers/participant/application_controller.rb
class Participant::ApplicationController < ::ApplicationController
  before_action :set_participant

  private

  def set_participant
    @participant = ::Participant.find_by!(access_token: params[:access_token])
  end
end

# app/controllers/participant/clouds_controller.rb
class Participant::CloudsController < Participant::ApplicationController
  # @participant is automatically set
  def index
    @clouds = @participant.clouds.recent
  end
end
```

All routes under `Participant::` are automatically scoped. No need for concerns or custom modules.

## Use `before_action` for Precondition Guards

**Preconditions** (auth, resource loading, feature gates, cooldowns) belong in `before_action` hooks — not inline in the action.

**Bad (inline guards):**
```ruby
class MatchRefreshesController < AuthenticatedController
  def create
    sub = current_account.subs.find_by(active: true)
    return redirect_back_or_to root_path, alert: "No active subscription." unless sub
    return redirect_back_or_to root_path, alert: "Link your Riot account first." unless current_account.riot_linked?
    return redirect_back_or_to root_path, alert: "Please wait before refreshing again." unless sub.refresh_cooldown_elapsed?

    MatchTrackingSubJob.perform_later(sub)
    redirect_back_or_to root_path, notice: "Refreshing your matches..."
  end
end
```

**Good (`before_action` hooks):**
```ruby
class MatchRefreshesController < AuthenticatedController
  before_action :require_active_sub
  before_action :require_riot_link
  before_action :require_cooldown_elapsed

  def create
    MatchTrackingSubJob.perform_later(active_sub)
    redirect_back_or_to root_path, notice: "Refreshing your matches..."
  end

  private

  def active_sub
    @active_sub ||= current_account.subs.find_by(active: true)
  end

  def require_active_sub
    redirect_back_or_to root_path, alert: "No active subscription." unless active_sub
  end

  def require_riot_link
    redirect_back_or_to root_path, alert: "Link your Riot account first." unless current_account.riot_linked?
  end

  def require_cooldown_elapsed
    redirect_back_or_to root_path, alert: "Please wait before refreshing again." unless active_sub.refresh_cooldown_elapsed?
  end
end
```

**Why:** Actions stay minimal (1-3 lines), guards are reusable across actions, and the preconditions are visible at the top of the class.

## Return Early for Action-Specific Logic

For logic that only applies within a single action (not a shared precondition), guard clauses are fine:

```ruby
def create
  return head 422 unless params[:name].present?

  cloud = @participant.clouds.create!(params.permit(:name))
  redirect_to cloud
end
```

## Don't Use Concerns for Business Logic

**Bad:**
```ruby
module TokenAuthenticated
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_by_token!
  end

  def authenticate_by_token!
    # ...
  end
end

class CloudsController < ApplicationController
  include TokenAuthenticated
end
```

**Good:**
```ruby
class Participant::ApplicationController < ApplicationController
  before_action :set_participant

  private

  def set_participant
    @participant = Participant.find_by!(access_token: params[:access_token])
  end
end

class Participant::CloudsController < Participant::ApplicationController
  # Inheritance handles scoping, no magic
end
```

Inheritance is clearer than concerns.
