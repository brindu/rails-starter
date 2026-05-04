---
description: Testing conventions — RSpec, FactoryBot, request/system/model spec layout, what to test and what to skip
globs:
  - spec/**/*.rb
  - .rspec
---

# Testing Patterns

## RSpec > Minitest

Use RSpec for better DSL and readability.

## Test Organization

```
spec/
├── models/          # Model logic
├── requests/        # Controller/HTTP responses
├── system/          # Full-stack browser tests (excluded by default)
├── factories/
├── support/
└── spec_helper.rb
```

## Model Tests: Logic & Validations

```ruby
describe Cloud do
  describe "#ready_to_generate?" do
    it "returns true when analyzed" do
      cloud = create(:cloud, state: :analyzed)
      expect(cloud.ready_to_generate?).to be true
    end

    it "returns false when generating" do
      cloud = create(:cloud, state: :generating)
      expect(cloud.ready_to_generate?).to be false
    end
  end

  describe "validations" do
    it "validates presence of participant_id" do
      cloud = build(:cloud, participant_id: nil)
      expect(cloud).not_to be_valid
    end
  end
end
```

## Request Tests: HTTP Behavior

```ruby
describe "Participant::CloudsController" do
  describe "POST /participant/:access_token/clouds" do
    it "creates a cloud when user can generate" do
      participant = create(:participant)
      blob = create(:active_storage_blob)

      expect do
        post participant_clouds_path(access_token: participant.access_token),
          params: { cloud: { blob_signed_id: blob.signed_id } }
      end.to change(Cloud, :count).by(1)

      expect(response).to redirect_to(participant_cloud_path(participant.access_token, Cloud.last))
    end
  end
end
```

## System Tests: Critical User Flows

```ruby
describe "Cloud generation flow", type: :system do
  it "generates a cloud from upload to display" do
    participant = create(:participant)

    visit participant_home_path(access_token: participant.access_token)
    click_button "Upload Image"

    # Upload interaction, assertions...
    expect(page).to have_content "Cloud generated"
  end
end
```

**Tip:** Exclude system tests by default in `spec_helper.rb`:
```ruby
RSpec.configure do |config|
  config.filter_run_excluding type: :system
end
```

Run with: `rspec --tag type:system`

## Use FactoryBot for Test Data

```ruby
# spec/factories/participants.rb
FactoryBot.define do
  factory :participant do
    full_name { Faker::Name.name }
    email { Faker::Internet.email }

    trait :with_cloud do
      after(:create) do |participant|
        create(:cloud, participant:)
      end
    end
  end
end

# In tests
participant = create(:participant, :with_cloud)
```

## Don't Test Framework Behavior

**Skip these tests:**
- ActiveRecord callbacks (framework tests these)
- Basic CRUD (framework tests these)
- Model associations (too simple to break)
- Generated code (don't test the generator output)

**Test these:**
- Custom validations
- Business logic methods
- Controller responses
- Integration flows

## Running Tests

```bash
# All tests
rspec

# Specific model
rspec spec/models/cloud_spec.rb

# Exclude system tests (slow)
rspec --tag ~type:system

# Only system tests
rspec --tag type:system

# Verbose output
rspec -f d
```
