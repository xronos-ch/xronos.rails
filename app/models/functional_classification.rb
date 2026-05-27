# == Schema Information
#
# Table name: functional_classifications
#
#  id                                      :bigint           not null, primary key
#  assignable_type                         :string           not null
#  note                                    :text
#  source                                  :string
#  created_at                              :datetime         not null
#  updated_at                              :datetime         not null
#  assignable_id                           :bigint           not null
#  functional_classification_category_id   :bigint           not null
#  functional_classification_confidence_id :bigint           not null
#
# Indexes
#
#  idx_functional_classifications_unique_category             (assignable_type,assignable_id,functional_classification_category_id) UNIQUE
#  idx_on_functional_classification_category_id_0cc23f287f    (functional_classification_category_id)
#  idx_on_functional_classification_confidence_id_882617d1c0  (functional_classification_confidence_id)
#  index_functional_classifications_on_assignable             (assignable_type,assignable_id)
#
# Foreign Keys
#
#  fk_rails_...  (functional_classification_category_id => functional_classification_categories.id)
#  fk_rails_...  (functional_classification_confidence_id => functional_classification_confidences.id)
#
class FunctionalClassification < ApplicationRecord
  belongs_to :assignable, polymorphic: true
  belongs_to :functional_classification_category
  belongs_to :functional_classification_confidence

  validates :functional_classification_category_id,
            uniqueness: {
              scope: [:assignable_type, :assignable_id],
              message: "has already been assigned to this record"
            }
  has_paper_trail

  acts_as_copy_target # enable CSV exports

  def self.label
    "functional classification"
  end

end
