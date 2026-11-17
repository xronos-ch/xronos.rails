# test/factories/functional_classifications.rb

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
FactoryBot.define do
  factory :functional_classification do
    association :assignable, factory: :context
    association :functional_classification_category
    confidence { :possible }
    source { "Test source" }
    note { "Test note" }
  end
end
