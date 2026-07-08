class Supersession < ApplicationRecord
  belongs_to :superseded,    polymorphic: true
  belongs_to :superseded_by, polymorphic: true

  # Cache of currently-active supersessions. SupersessionEvent is the
  # source of truth. If these two disagree, the event log wins; call
  # `Supersession.rebuild_from_events!` to restore this table from it.
  #
  # Used as a fast index for the Supersedable default scope: a record
  # is "superseded" iff a Supersession row exists for it. The unique
  # index on (superseded_type, superseded_id) enforces the invariant
  # "at most one current supersession per record" at the DB level.

  # Rebuild the cache from the event log. Walks events in order,
  # maintaining an in-memory {superseded_record => canonical_record}
  # map, and inserts/deletes Supersession rows to match. The
  # invariant: after this method returns, the set of Supersession rows
  # equals the set of records that have a 'supersede' event with no
  # later 'restore' event.
  def self.rebuild_from_events! # rubocop:disable Metrics/MethodLength
    transaction do
      delete_all

      active = {}

      SupersessionEvent.order(:created_at, :id).each do |event|
        key = [event.superseded_type, event.superseded_id]
        case event.event_type
        when 'supersede'
          active[key] = [event.superseded_by_type, event.superseded_by_id]
        when 'restore'
          active.delete(key)
        end
      end

      active.each do |(stype, sid), (btype, bid)|
        create!(
          superseded_type: stype,
          superseded_id: sid,
          superseded_by_type: btype,
          superseded_by_id: bid
        )
      end
    end
  end
end
