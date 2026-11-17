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
class ControlledVocabulary::Term < ApplicationRecord
  belongs_to :vocabulary, class_name: "ControlledVocabulary",
                         foreign_key: :controlled_vocabulary_id
  has_many :variants, class_name: "ControlledVocabulary::Variant",
                      foreign_key: :controlled_vocabulary_term_id,
                      dependent: :destroy

  default_scope { order(:name) }

  validates :name, presence: true,
                   uniqueness: { scope: [:controlled_vocabulary_id, :ontology_name] }

  with_options if: -> { ontology_name.present? || ontology_id.present? } do
    validates :ontology_name, presence: true
    validates :ontology_id, presence: true
    validates :ontology_name, uniqueness: { scope: :ontology_id }
  end

  include PgSearch::Model
  pg_search_scope :search,
    against: :name,
    using: { tsearch: { prefix: true } }

  # Canonical OBO PURL for the term. The stored +ontology_id+ is in
  # "PREFIX:NNNNNNN" form (e.g. "UBERON:0000029"); the PURL replaces the
  # colon with an underscore (e.g. "UBERON_0000029"). OBOLibrary redirects
  # the PURL to the appropriate per-ontology viewer (OLS for UBERON,
  # Planteome for PO, etc.) so we don't have to maintain per-ontology
  # templates here.
  def ontology_url
    return nil if ontology_id.blank?
    "http://purl.obolibrary.org/obo/#{ontology_id.tr(':', '_')}"
  end

  # Truncated plain-text description for API responses
  def description_excerpt(max: 200)
    return nil if description.blank?
    description.length > max ? "#{description[0, max].rstrip}…" : description
  end
end
