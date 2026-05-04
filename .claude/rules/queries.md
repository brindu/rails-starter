---
description: Query objects for complex/reusable queries — ApplicationQuery base, namespaced under their model
globs:
  - app/models/**/*_query.rb
  - app/models/application_query.rb
---

# Query Objects

## Use Query Objects for Complex Queries

**When:**
- Query has multiple conditions
- Query is reused across controllers
- Query is easier to test in isolation

**Pattern:**
```ruby
# app/models/application_query.rb
class ApplicationQuery
  class << self
    attr_writer :query_model_name

    def query_model_name
      @query_model_name ||= name.sub(/::[^:]+$/, "")
    end

    def query_model
      query_model_name.safe_constantize
    end

    def call(...)
      new.call(...)
    end
  end

  private attr_reader :relation

  def initialize(relation = self.class.query_model.all)
    @relation = relation
  end

  def call
    relation
  end
end

# app/models/participant/pending_query.rb
class Participant::PendingQuery < ApplicationQuery
  def call
    relation
      .without_picked_cloud
      .where(blocked: false)
      .order(created_at: :desc)
  end
end
```

**Usage:**
```ruby
# In controller
@pending = Participant::PendingQuery.call

# Or with a relation
@pending = Participant::PendingQuery.new(Participant.active).call
```
