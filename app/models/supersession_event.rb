# == Schema Information
#
# Table name: supersession_events
# Database name: primary
#
#  id                 :bigint           not null, primary key
#  comment            :text
#  event_type         :string           not null
#  superseded_by_type :string           not null
#  superseded_type    :string           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  superseded_by_id   :bigint           not null
#  superseded_id      :bigint           not null
#
# Indexes
#
#  index_supersession_events_on_event_type     (event_type,created_at)
#  index_supersession_events_on_superseded     (superseded_type,superseded_id,created_at)
#  index_supersession_events_on_superseded_by  (superseded_by_type,superseded_by_id,created_at)
#
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
