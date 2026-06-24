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
#  index_cv_terms_on_ontology             (ontology_name,ontology_id) UNIQUE WHERE ((ontology_name IS NOT NULL) AND (ontology_id IS NOT NULL))
#  index_cv_terms_on_vocabulary_and_name  (controlled_vocabulary_id,name) UNIQUE
#
class ControlledVocabulary::Term < ApplicationRecord
  belongs_to :vocabulary, class_name: "ControlledVocabulary",
                         foreign_key: :controlled_vocabulary_id
  has_many :variants, class_name: "ControlledVocabulary::Variant",
                      foreign_key: :controlled_vocabulary_term_id,
                      dependent: :destroy

  default_scope { order(:name) }

  validates :name, presence: true,
                   uniqueness: { scope: :controlled_vocabulary_id }

  with_options if: -> { ontology_name.present? || ontology_id.present? } do
    validates :ontology_name, presence: true
    validates :ontology_id, presence: true
    validates :ontology_name, uniqueness: { scope: :ontology_id }
  end

  ONTOLOGY_URL_TEMPLATES = {
    "UBERON" => "https://www.ebi.ac.uk/ols4/ontologies/uberon/terms?iri=http://purl.obolibrary.org/obo/%s",
    "PO"     => "https://www.ebi.ac.uk/ols4/ontologies/po/terms?iri=http://purl.obolibrary.org/obo/%s"
  }.freeze

  def ontology_url
    template = ONTOLOGY_URL_TEMPLATES[ontology_name]
    template && ontology_id ? template % ontology_id : nil
  end
end
