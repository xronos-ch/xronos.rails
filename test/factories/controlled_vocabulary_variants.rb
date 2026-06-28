# == Schema Information
#
# Table name: controlled_vocabulary_variants
# Database name: primary
#
#  id                            :bigint           not null, primary key
#  normalized                    :string           not null
#  value                         :string           not null
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  controlled_vocabulary_term_id :bigint           not null
#
# Indexes
#
#  index_cv_variants_on_term_and_normalized  (controlled_vocabulary_term_id,normalized) UNIQUE
#  index_cv_variants_on_term_and_value       (controlled_vocabulary_term_id,value) UNIQUE
#
FactoryBot.define do
  factory :controlled_vocabulary_variant,
          class: "ControlledVocabulary::Variant" do
    association :term, factory: :controlled_vocabulary_term
    sequence(:value) { |n| "variant #{n}" }
  end
end
