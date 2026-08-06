# == Schema Information
#
# Table name: citations
# Database name: primary
#
#  id           :bigint           not null, primary key
#  citing_type  :string
#  citing_id    :bigint
#  reference_id :bigint
#
# Indexes
#
#  index_citations_on_citing                (citing_type,citing_id)
#  index_citations_on_citing_and_reference  (citing_type,citing_id,reference_id) UNIQUE
#  index_citations_on_reference_id          (reference_id)
#

class Citation < ApplicationRecord
  include Mergeable

  exact_duplicates_on :citing_type, :citing_id, :reference_id

  # No `after_save :merge_exact_duplicates` here. The unique index on
  # (citing_type, citing_id, reference_id) prevents creation of new
  # duplicates; the rake task handles the backlog of existing duplicates.

  belongs_to :citing, polymorphic: true
  belongs_to :reference

  validates :reference,
            uniqueness: {
              scope: %i[citing_type citing_id],
              message: "has already been cited for this record"
            }

  acts_as_copy_target # enable CSV exports

  after_destroy :destroy_reference_if_orphaned

  def destroy_reference_if_orphaned
    reference.destroy_if_orphaned
  end

  def self.label
    "citation"
  end

  def self.icon
    "icons/citation.svg"
  end

  # Reassign all citations owned by `from` to `to`. Handles the
  # `(citing_type, citing_id, reference_id)` unique index by destroying
  # any dupe citation whose tuple is already present on `to`.
  #
  # When `from` is a Reference, the reassignment follows
  # `reference_id`. When `from` is any other model, the reassignment
  # follows `(citing_type, citing_id)`.
  #
  # Must be called from within a transaction (e.g. a `before_merge`
  # callback); the dupe is expected to be soft-deleted (Supersedable) so
  # `dependent: :destroy` will not clean up unhandled rows.
  def self.reassign_all_to!(from:, to:)
    raise ArgumentError, "from and to must be the same class" unless from.instance_of?(to.class)
    raise ArgumentError, "to must be persisted" unless to.persisted?
    raise ArgumentError, "from and to must be different records" if from.id == to.id

    if from.is_a?(Reference)
      reassign_reference_id!(from: from, to: to)
    else
      reassign_citing_id!(from: from, to: to)
    end
  end

  def self.reassign_reference_id!(from:, to:)
    # A collision occurs when the canonical already has a citation with
    # the same (citing_type, citing_id) as one of the dupe's citations;
    # the reassignment would then violate the unique index.
    destroyed = delete_citing_collisions(reference_id: from.id, to_id: to.id)

    reassigned = where(reference_id: from.id).update_all(reference_id: to.id)

    { reassigned: reassigned, destroyed_collisions: destroyed }
  end

  def self.reassign_citing_id!(from:, to:)
    type = from.class.name

    # A collision occurs when the canonical already cites the same
    # reference as one of the dupe's citations.
    canonical_refs = where(citing_type: type, citing_id: to.id).pluck(:reference_id)
    destroyed = where(citing_type: type, citing_id: from.id)
                .where(reference_id: canonical_refs.empty? ? nil : canonical_refs)
                .delete_all

    reassigned = where(citing_type: type, citing_id: from.id).update_all(citing_id: to.id)

    { reassigned: reassigned, destroyed_collisions: destroyed }
  end

  # Delete dupe citations whose (citing_type, citing_id) matches one of
  # the canonical's (to_id) citations. Uses an EXISTS subquery so the
  # SQL planner doesn't have to expand a huge row-value IN clause.
  def self.delete_citing_collisions(reference_id:, to_id:)
    where(reference_id: reference_id)
      .where(
        "EXISTS (SELECT 1 FROM citations canonical " \
        "WHERE canonical.reference_id = ? " \
        "AND canonical.citing_type = citations.citing_type " \
        "AND canonical.citing_id = citations.citing_id)",
        to_id
      )
      .delete_all
  end
end
