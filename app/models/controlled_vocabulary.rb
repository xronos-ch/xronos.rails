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

  # Exact, case-sensitive name lookup. For fuzzy lookups, use #resolve_variant.
  def match(input)
    terms.find_by(name: input)
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
end
