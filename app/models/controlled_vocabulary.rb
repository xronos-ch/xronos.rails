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

  # Look up a term in this vocabulary by user-typed input.
  # 1) match a known variant (case-insensitive on the stored normalized form)
  # 2) fall back to an exact term name match (case-insensitive)
  def match(input)
    needle = input.to_s.downcase.strip
    return nil if needle.blank?

    via_variant = terms.joins(:variants)
      .where(controlled_vocabulary_variants: { normalized: needle })
      .first
    return via_variant if via_variant

    terms.find_by("LOWER(name) = ?", needle)
  end
end
