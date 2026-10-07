# == Schema Information
#
# Table name: functional_classifications
# Database name: primary
#
#  id                                    :bigint           not null, primary key
#  assignable_type                       :string           not null
#  confidence                            :integer          default("possible"), not null
#  note                                  :text
#  source                                :string
#  created_at                            :datetime         not null
#  updated_at                            :datetime         not null
#  assignable_id                         :bigint           not null
#  functional_classification_category_id :bigint           not null
#
# Indexes
#
#  idx_functional_classifications_unique_category           (assignable_type,assignable_id,functional_classification_category_id) UNIQUE
#  idx_on_functional_classification_category_id_0cc23f287f  (functional_classification_category_id)
#  index_functional_classifications_on_assignable           (assignable_type,assignable_id)
#
# Foreign Keys
#
#  fk_rails_...  (functional_classification_category_id => functional_classification_categories.id)
#
class FunctionalClassification < ApplicationRecord
  include Peripheral

  belongs_to :assignable, polymorphic: true, touch: true
  belongs_to :functional_classification_category

  enum :confidence, {
    unknown: 0,
    possible: 1,
    probable: 2,
    secure: 3
  }

  validates :functional_classification_category_id,
            uniqueness: {
              scope: [:assignable_type, :assignable_id],
              message: "has already been assigned to this record"
            }

  validates :confidence, presence: true

  revision_comment_parent :assignable

  has_paper_trail
  acts_as_copy_target

  def self.label
    "functional classification"
  end

  # Reassign all functional_classifications owned by `from` to `to`.
  # Handles the (assignable_type, assignable_id,
  # functional_classification_category_id) unique index by destroying
  # any dupe whose category is already present on `to`.
  #
  # `from` must be an Assignable model (Site or Context); the
  # `assignable_type` is derived from `from.class.name`.
  #
  # Must be called from within a transaction (e.g. a `before_merge`
  # callback); the dupe is expected to be soft-deleted (Supersedable)
  # so `dependent: :destroy` will not clean up unhandled rows.
  def self.reassign_all_to!(from:, to:)
    raise ArgumentError, "from and to must be the same class" unless from.instance_of?(to.class)
    raise ArgumentError, "to must be persisted" unless to.persisted?
    raise ArgumentError, "from and to must be different records" if from.id == to.id

    from_filter = { assignable_type: from.class.name, assignable_id: from.id }
    to_filter   = { assignable_type: to.class.name,   assignable_id: to.id }

    destroyed  = destroy_category_collisions(from_filter, to_filter)
    reassigned = where(from_filter).update_all(assignable_id: to.id)

    { reassigned: reassigned, destroyed_collisions: destroyed }
  end

  def self.destroy_category_collisions(from_filter, to_filter)
    canonical_categories = where(to_filter).pluck(:functional_classification_category_id)
    return 0 if canonical_categories.empty?

    where(from_filter)
      .where(functional_classification_category_id: canonical_categories)
      .delete_all
  end
end
