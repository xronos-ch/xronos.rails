module Supersedable
  # Reflections excluded from reassignment: `versions` (paper_trail metadata
  # must not be rewritten) and `pg_search_document` (managed separately by
  # pg_search).
  EXCLUDED_REFLECTIONS = %w[versions pg_search_document supersession supersession_events].freeze

  CHILD_REFLECTIONS = [
    ActiveRecord::Reflection::HasOneReflection,
    ActiveRecord::Reflection::HasManyReflection,
    ActiveRecord::Reflection::HasAndBelongsToManyReflection
  ].freeze

  extend ActiveSupport::Concern

  included do # instance methods
    has_one  :supersession, as: :superseded, dependent: :destroy
    has_many :supersession_events, as: :superseded

    # Default scope: hide records that have a current Supersession row.
    # The unique index on supersessions.superseded_id makes this an
    # index-only subquery.
    default_scope { where.not(id: Supersession.select(:superseded_id)) }
  end

  def supersedable?
    true
  end

  def superseded?
    supersession.present?
  end

  def not_superseded?
    !superseded?
  end

  # Walks the supersession graph to the current canonical,
  # non-superseded record. Self is the base case. The unique index on
  # supersessions.superseded_id guarantees there is at most one
  # Supersession row per record, so this terminates.
  def ultimately_superseded_by
    return self unless superseded?

    supersession.superseded_by.ultimately_superseded_by
  end

  # Append-only event log view of this record's supersession history.
  def merge_history
    supersession_events.order(:created_at)
  end

  # Make `self` superseded by `canonical`. Atomic: writes the
  # SupersessionEvent row and the Supersession row in one transaction,
  # and reassigns all eligible child associations to the canonical.
  #
  # When `self` is being merged, any other records that are currently
  # superseded by `self` are re-pointed to the new canonical. This
  # preserves the invariant that every Supersession row points at a
  # currently-canonical record.
  #
  # Preconditions:
  #   - `canonical` must not be `self`
  #   - `self` must not already be superseded
  #   - `canonical` must currently be canonical (not superseded)
  # The unique index on supersessions.superseded_id is the DB-level
  # safety net.
  def supersede!(canonical, revision_comment = nil) # rubocop:disable Metrics/MethodLength
    raise ArgumentError, "Cannot supersede a record by itself" if canonical == self
    raise 'Record is already superseded' if superseded?
    raise 'Cannot supersede into a superseded record' if canonical.superseded?

    transaction do
      re_point_existing_supersessions_to(canonical)

      supersession_state = Supersession.create!(superseded: self, superseded_by: canonical)
      self.supersession = supersession_state
      SupersessionEvent.create!(
        event_type: 'supersede',
        superseded: self,
        superseded_by: canonical,
        comment: revision_comment
      )
      reassign_associations!(revision_comment, supersession_state)
    end
  end

  # Restore `self` to canonical. Removes the current Supersession row
  # and appends a 'restore' event. The re-pointing case (where the
  # original target was itself superseded after the original merge) is
  # handled inside `supersede!` at the time the target was superseded,
  # not here, so this method stays simple.
  def restore! # rubocop:disable Metrics/MethodLength
    raise 'Not currently superseded' unless superseded?

    old_target = supersession.superseded_by
    transaction do
      supersession.destroy!
      SupersessionEvent.create!(
        event_type: 'restore',
        superseded: self,
        superseded_by: old_target
      )
    end
  ensure
    # Clear the in-memory association cache so a follow-up
    # supersede!() doesn't see a stale (now-destroyed) row.
    association(:supersession).reset
  end

  class_methods do
    # Returns the set of reflections whose child records should be
    # reassigned when a record is superseded. Excludes through-reflections
    # (those are navigated via the underlying has_many), HABTM
    # (TODO), and the supersession bookkeeping itself.
    def supersedable_associations
      reflections
        .reject { |k, _v| EXCLUDED_REFLECTIONS.include?(k) }
        .select { |_k, v| direct_child_reflection?(v) }
    end

    private

    def direct_child_reflection?(reflection)
      return false if reflection.is_a?(ActiveRecord::Reflection::ThroughReflection)
      return false if reflection.is_a?(ActiveRecord::Reflection::HasAndBelongsToManyReflection)

      CHILD_REFLECTIONS.any? { |klass| reflection.is_a?(klass) }
    end
  end

  private # rubocop:disable Lint/UselessAccessModifier

  def reassign_associations!(revision_comment, supersession_state = nil)
    supersession_state ||= supersession
    target_id = supersession_state.superseded_by_id
    self.class.supersedable_associations.each_value do |reflection|
      send(reflection.name).each do |child|
        child.write_attribute(reflection.foreign_key, target_id)
        child.revision_comment = revision_comment if child.respond_to?(:revision_comment=)
        child.save!
      end
    end
  end

  def re_point_existing_supersessions_to(canonical)
    Supersession
      .where(superseded_by: self)
      .where.not(superseded: canonical)
      .update_all(
        superseded_by_type: canonical.class.name,
        superseded_by_id: canonical.id,
        updated_at: Time.current
      )
  end
end
