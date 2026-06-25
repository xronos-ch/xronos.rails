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
  has_many :terms, class_name: "ControlledVocabulary::Term", dependent: :destroy
  has_many :variants, through: :terms

  default_scope { order(:name) }

  validates :name, presence: true, uniqueness: true

  def self.[](name) = find_by!(name: name)

  # Look up a term in this vocabulary by exact, case-sensitive name match.
  # Fuzzy case-insensitive lookups (e.g. for form UIs) compose against the
  # variant thesaurus directly.
  def match(input)
    terms.find_by(name: input)
  end

  # Resolve a user-typed string to its canonical term via the variant
  # thesaurus. Returns the ControlledVocabulary::Term linked to the
  # matching variant, or nil if no variant matches.
  #
  # Case-insensitive (input is downcased and stripped to match the
  # stored `normalized` form on ControlledVocabulary::Variant).
  #
  # This is the inverse of the variant system: callers that record a
  # variant when the user accepts a suggestion use this to look it up
  # next time. For exact-name lookups, use #match.
  def resolve_variant(input)
    return nil if input.blank?
    needle = ControlledVocabulary::Variant.normalize_for_matching(input)
    return nil if needle.empty?

    terms.joins(:variants)
      .find_by(controlled_vocabulary_variants: { normalized: needle })
  end
end
