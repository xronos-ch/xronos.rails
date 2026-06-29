# == Schema Information
#
# Table name: controlled_vocabularies
# Database name: primary
#
#  id          :bigint           not null, primary key
#  description :text
#  name        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_controlled_vocabularies_on_name  (name) UNIQUE
#
class ControlledVocabulary < ApplicationRecord
  has_many :terms, class_name: 'ControlledVocabulary::Term', dependent: :destroy
  has_many :variants, through: :terms

  default_scope { order(:name) }

  validates :name, presence: true, uniqueness: true

  def self.[](name) = find_by!(name: name)

  # Exact, case-sensitive name lookup. For fuzzy lookups, use
  # #resolve_variant. Returns a single term or nil.
  #
  # When multiple terms in the vocabulary share a name (e.g. PO and UBERON
  # both have a term called "cortex"), the first match is returned in a
  # deterministic order: +ontology_name+ ascending, then +id+ ascending.
  # That means a plant ontology term (PO) will win over UBERON for an
  # ambiguous name. Use #matches when the caller needs the full set.
  def match(input)
    return nil if input.blank?
    matches(input).first
  end

  # Plural form of #match. Returns an ActiveRecord::Relation of all terms
  # whose +name+ equals +input+ exactly (case-sensitive), ordered
  # +ontology_name+ then +id+ for a stable iteration order. Empty for
  # blank or unknown input.
  def matches(input)
    return terms.none if input.blank?
    terms.where(name: input).order(:ontology_name, :id)
  end

  # Case-insensitive lookup against the variant thesaurus. Returns the
  # term whose variant matches the normalised input, or nil.
  def resolve_variant(input)
    return nil if input.blank?

    needle = ControlledVocabulary::Variant.normalize_for_matching(input)
    return nil if needle.empty?

    terms.joins(:variants)
         .find_by(controlled_vocabulary_variants: { normalized: needle })
  end

  # Prefix-style variant search. Returns an Array of
  # ControlledVocabulary::Variant records, scoped to this vocabulary,
  # ranked by pg_search relevance, deduped by term (one variant per
  # term, the highest-ranked one).  Returns +limit+ or fewer. Overfetches by 
  # 3x internally to compensate for term-level dedup; a single term may have 
  # many matching variants.
  def search_variants(input, limit: 20)
    return [] if input.blank?

    needle = ControlledVocabulary::Variant.normalize_for_matching(input)
    return [] if needle.empty?

    ControlledVocabulary::Variant.search(needle)
      .includes(:term)
      .joins(:term)
      .where(controlled_vocabulary_terms: { controlled_vocabulary_id: id })
      .limit(limit * 3)
      .to_a
      .uniq { |v| v.controlled_vocabulary_term_id }
      .first(limit)
  end
end
