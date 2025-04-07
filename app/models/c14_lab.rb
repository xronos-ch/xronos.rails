# == Schema Information
#
# Table name: c14_labs
#
#  id           :bigint           not null, primary key
#  active       :boolean
#  country_code :string
#  name         :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_c14_labs_on_active  (active)
#  index_c14_labs_on_name    (name)
#
class C14Lab < ApplicationRecord

  default_scope { order(active: :desc, name: :asc) }

  validates :name, presence: true

  has_many :c14_lab_codes
  has_many :c14s, inverse_of: :c14_lab
  has_paper_trail

  acts_as_copy_target # enable CSV exports

  scope :with_c14s_count, -> { select <<~SQL
      "c14_labs".*,
      (
        SELECT COUNT(c14s.id) 
        FROM c14s
        WHERE c14_lab_id = "c14_labs".id
      ) AS c14s_count
    SQL
  }

  def self.label
    "radiocarbon lab"
  end

  def lab_code
    # TODO: There can only be one...
    c14_lab_codes.select(canonical: true).first.lab_code
  end

  def country
    return nil if country_code.blank?
    ISO3166::Country[country_code] || 
      ISO3166::Country.find_country_by_any_name(country_code)
  end

  def c14s_count
    c14s.count
  end

  def distinct_methods
    c14s.distinct(:method).pluck(:method)
  end

end
