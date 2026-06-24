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

  private

  def compute_normalized
    self.normalized = value.to_s.downcase.strip
  end
end
