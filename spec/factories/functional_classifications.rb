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
FactoryBot.define do
  factory :functional_classification do
    assignable { nil }
    functional_classification_category { nil }
    functional_classification_confidence { nil }
    source { "MyString" }
    note { "MyText" }
  end
end
