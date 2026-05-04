---
description: Database design and migration conventions — normalization, foreign keys, constraints, counter caches, PostgreSQL enums, indexes
globs:
  - db/migrate/**/*.rb
  - db/schema.rb
---

# Database Design & Migrations

## Normalize Data: One Concern Per Table

**Bad (Denormalized):**
```ruby
create_table :participants do |t|
  t.string :email
  t.string :full_name
  t.datetime :invitation_sent_at
  t.datetime :invitation_opened_at
  t.string :bounce_type
  t.datetime :bounced_at
  t.boolean :invitation_resend_requested
  # Everything crammed together
end
```

**Good (Normalized):**
```ruby
create_table :participants do |t|
  t.string :email, null: false
  t.string :full_name, null: false
  t.string :access_token
  t.integer :cloud_generations_quota, default: 5
  t.integer :cloud_generations_count, default: 0
  t.integer :invitations_count, default: 0
  t.timestamps
end

create_table :invitations do |t|
  t.integer :participant_id, null: false, foreign_key: true
  t.enum :status, enum_type: :invitation_status, default: "sent"
  t.datetime :opened_at
  t.string :bounce_type
  t.datetime :bounced_at
  t.timestamps
end

create_table :clouds do |t|
  t.integer :participant_id, null: false, foreign_key: true
  t.enum :state, enum_type: :cloud_state, default: "uploaded"
  t.boolean :picked, default: false
  t.string :failure_reason
  t.timestamps
end
```

Each concern is a separate table. Easier to query, easier to extend, easier to analyze.

## Use Foreign Keys & Constraints

```ruby
create_table :clouds do |t|
  t.integer :participant_id, null: false
  t.foreign_key :participants, column: :participant_id, on_delete: :cascade
  t.enum :state, enum_type: :cloud_state, default: "uploaded", null: false
  t.timestamps
end

add_check_constraint :participants, "cloud_generations_count <= cloud_generations_quota"
```

Database enforces relationships and rules. Application bugs can't create invalid states.

## Use Counter Caches

```ruby
class CreateClouds < ActiveRecord::Migration[7.0]
  def change
    create_table :clouds do |t|
      t.integer :participant_id, null: false, foreign_key: true
      t.integer :participant_id
      t.foreign_key :participants, column: :participant_id
      t.timestamps
    end

    add_column :participants, :cloud_generations_count, :integer, default: 0, null: false
  end
end
```

Counter cache is a denormalization for performance. No N+1 queries.

## Enums in the Database

**Only in PostgreSQL**

```ruby
create_enum :cloud_state, ["uploaded", "analyzing", "analyzed", "generating", "generated", "failed"]
create_enum :invitation_status, ["sent", "opened", "bounced", "unsubscribed"]

create_table :clouds do |t|
  t.enum :state, enum_type: :cloud_state, default: "uploaded", null: false
end

create_table :invitations do |t|
  t.enum :status, enum_type: :invitation_status, default: "sent", null: false
end
```

Database-level enums prevent invalid states at the database layer.

## Indexes

```ruby
create_table :clouds do |t|
  t.integer :participant_id
  t.enum :state
  t.boolean :picked

  t.index [:participant_id, :state]  # Composite index
  t.index :picked
end
```

Index on:
- Foreign keys
- Frequently queried columns
- Enum state columns
- Columns in scopes

## Production-Ready Constraints

Always add to migrations:
```ruby
add_null_constraint :clouds, :participant_id
add_check_constraint :participants, "cloud_generations_count <= cloud_generations_quota"
add_foreign_key :clouds, :participants, on_delete: :cascade
```

Database prevents invalid states.
