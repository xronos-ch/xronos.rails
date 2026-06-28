# == Schema Information
#
# Table name: controlled_vocabulary_terms
# Database name: primary
#
#  id                       :bigint           not null, primary key
#  description              :text
#  name                     :string           not null
#  ontology_name            :string
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  controlled_vocabulary_id :bigint           not null
#  ontology_id              :string
#
# Indexes
#
#  index_cv_terms_on_ontology                      (ontology_name,ontology_id) UNIQUE WHERE ((ontology_name IS NOT NULL) AND (ontology_id IS NOT NULL))
#  index_cv_terms_on_vocabulary_ontology_and_name  (controlled_vocabulary_id,ontology_name,name) UNIQUE
#
FactoryBot.define do
  factory :controlled_vocabulary_term,
          class: "ControlledVocabulary::Term" do
    association :vocabulary, factory: :controlled_vocabulary
    sequence(:name) { |n| "Term #{n}" }
    description { "Test term" }
  end
end
