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
class ControlledVocabulary::Variant < ApplicationRecord
  belongs_to :term, class_name: "ControlledVocabulary::Term",
                    foreign_key: :controlled_vocabulary_term_id

  before_validation :compute_normalized

  validates :value,      presence: true, uniqueness: { scope: :controlled_vocabulary_term_id }
  validates :normalized, presence: true, uniqueness: { scope: :controlled_vocabulary_term_id }

  include PgSearch::Model
  pg_search_scope :search,
    against: :normalized,
    using: { tsearch: { prefix: true } }

  # Normalize a value for variant matching: downcase, strip ends, collapse
  # internal whitespace. Used by #compute_normalized (when storing) and
  # by ControlledVocabulary#resolve_variant (when looking up). The two
  # sides must agree; if they ever drift, matches silently break.
  def self.normalize_for_matching(value)
    value.to_s.downcase.squish
  end

  private

  def compute_normalized
    self.normalized = self.class.normalize_for_matching(value)
  end
end
