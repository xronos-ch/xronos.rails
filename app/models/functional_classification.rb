# == Schema Information
#
# Table name: functional_classifications
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
  belongs_to :assignable, polymorphic: true
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

  has_paper_trail
  acts_as_copy_target

  def self.label
    "functional classification"
  end
end
