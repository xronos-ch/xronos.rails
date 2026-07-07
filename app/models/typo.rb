# == Schema Information
#
# Table name: typos
# Database name: primary
#
#  id                :bigint           not null, primary key
#  approx_end_time   :integer
#  approx_start_time :integer
#  name              :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  parent_id         :integer
#  sample_id         :bigint
#
# Indexes
#
#  index_typos_on_name                           (name)
#  index_typos_on_name_sample_id_and_created_at  (name,sample_id,created_at)
#  index_typos_on_sample_id                      (sample_id)
#

class Typo < Chron
  exact_duplicates_on :name,
                      :sample_id,
                      approx_start_time: :nil_matches_nil,
                      approx_end_time: :nil_matches_nil

  validates :name, presence: true

  include PgSearch::Model
  pg_search_scope :search,
                  against: :name,
                  using: { tsearch: { prefix: true } } # match partial words
  # multisearchable against: :name # needs to be cleaned up a bit more

  def self.label
    'typological date'
  end

  def self.icon
    'icons/typo.svg'
  end

  def age
    return nil if approx_start_time.blank? && approx_end_time.blank?

    "#{approx_start_time}–#{approx_end_time}"
  end
end
