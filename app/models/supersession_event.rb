class SupersessionEvent < ApplicationRecord
  belongs_to :superseded,    polymorphic: true
  belongs_to :superseded_by, polymorphic: true

  EVENT_TYPES = %w[supersede restore].freeze
  validates :event_type, inclusion: { in: EVENT_TYPES }
  validate  :not_self_supersession

  # Append-only by contract; enforced at the application layer.
  before_update  :prevent_mutation
  before_destroy :prevent_mutation

  private

  def not_self_supersession
    return unless superseded_type == superseded_by_type &&
                  superseded_id   == superseded_by_id

    errors.add(:superseded_by, 'cannot be the same as superseded')
  end

  def prevent_mutation
    raise ActiveRecord::ReadOnlyRecord,
          'SupersessionEvent is append-only; create a new event instead'
  end
end
