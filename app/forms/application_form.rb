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
