---
description: Form objects for multi-model operations — ApplicationForm base class, transactional save, ActiveModel attributes
globs:
  - app/forms/**/*.rb
---

# Form Objects

## Use Form Objects for Multi-Model Operations

**When:**
- Creating/updating multiple related records
- Complex validations across models
- Need transaction boundaries
- Want to decouple from controller

**Pattern:**
```ruby
# app/forms/application_form.rb
class ApplicationForm
  include ActiveModel::API
  include ActiveModel::Attributes
  include AfterCommitEverywhere

  define_callbacks :save, only: :after
  define_callbacks :commit, only: :after

  class << self
    def after_save(...)
      set_callback(:save, :after, ...)
    end

    def after_commit(...)
      set_callback(:commit, :after, ...)
    end

    def model_name
      @model_name ||= ActiveModel::Name.new(nil, nil, name.sub(/Form$/, ""))
    end
  end

  def save
    return false unless valid?

    with_transaction do
      after_commit { run_callbacks(:commit) }
      run_callbacks(:save) { submit! }
    end
  end

  private

  def with_transaction(&block)
    ApplicationRecord.transaction(&block)
  end

  def submit!
    raise NotImplementedError
  end
end

# app/forms/participant_registration_form.rb
class ParticipantRegistrationForm < ApplicationForm
  attribute :full_name, :string
  attribute :email, :string

  validates :full_name, :email, presence: true

  private

  def submit!
    participant = Participant.create!(
      full_name:,
      email:
    )

    invitation = participant.invitations.create!

    Mailer.send_invitation(invitation).deliver_later
  end
end
```

**In controller:**
```ruby
def create
  @form = ParticipantRegistrationForm.new(form_params)

  if @form.save
    redirect_to home_path
  else
    render :new
  end
end

private

def form_params
  params.require(:participant_registration_form).permit(:full_name, :email)
end
```
