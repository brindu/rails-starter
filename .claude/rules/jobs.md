---
description: Background job conventions — ActiveJob::Continuable for multi-step workflows, jobs orchestrate while models execute, error handling
globs:
  - app/jobs/**/*.rb
---

# Job Patterns

## Use ActiveJob::Continuable for Multi-Step Workflows

**Pattern:**
```ruby

# app/jobs/cloud_generation_job.rb
class CloudGenerationJob < ApplicationJob
  include ActiveJob::Continuable

  def perform(cloud)
    @cloud = cloud

    step :moderate, isolated: true
    step :generate, isolated: true unless cloud.failed?
  end

  private

  attr_reader :cloud

  def moderate(_step)
    cloud.update!(state: :analyzing)

    detector = Cloud::NSFWDetector.new(cloud)
    if detector.check
      cloud.update!(state: :analyzed)
    else
      cloud.update!(state: :failed, failure_reason: "NSFW content detected")
    end
  rescue => err
    Rails.error.report(err, handled: true)
    cloud.update!(state: :failed, failure_reason: err.message)
  end

  def generate(_step)
    cloud.update!(state: :generating)

    generator = Cloud::CardGenerator.new(cloud)
    io = generator.generate

    cloud.generated_image.attach(
      io:,
      filename: "cloud-#{cloud.participant.slug}.png",
      content_type: "image/png"
    )

    cloud.update!(state: :generated)

    Turbo::StreamsChannel.broadcast_refresh_to(cloud)
  rescue => err
    Rails.error.report(err, handled: true)
    cloud.update!(state: :failed, failure_reason: err.message)
  end
end
```

**Why this pattern:**
- Each step is isolated (errors don't crash the whole job)
- Conditional steps (skip generate if moderation fails)
- Clear state transitions
- Error handling is consistent
- Progress visible to UI (via Turbo Streams)
- Retryable steps

**Key features:**
- `include ActiveJob::Continuable`
- `step :method_name, isolated: true` defines each step
- `isolated: true` means errors are caught and logged, job continues (or fails cleanly)
- Update model state after each step
- Broadcast progress for real-time updates

## Jobs Orchestrate, Models Execute

**Good separation:**
```ruby
# Job orchestrates workflow
class CloudGenerationJob < ApplicationJob
  def perform(cloud)
    step :generate
  end

  private

  def generate(_step)
    generator = Cloud::CardGenerator.new(cloud)
    io = generator.generate  # Delegates to model class
    cloud.generated_image.attach(io:, filename: "...")
  end
end

# Model class executes business logic
class Cloud::CardGenerator
  def initialize(cloud)
    @cloud = cloud
  end

  def generate
    # Complex API/processing logic here
    # Returns IO object or raises exception
    StringIO.new(decoded_image_data)
  end

  private

  def build_prompt
    # ...
  end

  def call_api(prompt)
    # ...
  end
end
```

**Don't put complex logic in jobs.** Jobs are for orchestration. Model classes handle complexity.

## Error Handling in Jobs

```ruby
def moderate(_step)
  # Do work
  cloud.update!(state: :analyzed)
rescue => err
  Rails.error.report(err, handled: true)  # Sends to Sentry if configured
  cloud.update!(state: :failed, failure_reason: err.message)
end
```

Always:
- Catch errors with `rescue => err`
- Report to error tracking (Rails.error.report)
- Update model state to reflect failure
- Don't re-raise unless you want the entire job to fail
