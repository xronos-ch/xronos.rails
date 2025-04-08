# == Schema Information
#
# Table name: c14_labs
#
#  id           :bigint           not null, primary key
#  active       :boolean
#  city         :string
#  country_code :string
#  name         :string
#  short_name   :string
#  url          :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  successor_id :bigint
#
# Indexes
#
#  index_c14_labs_on_active        (active)
#  index_c14_labs_on_name          (name)
#  index_c14_labs_on_short_name    (short_name) UNIQUE
#  index_c14_labs_on_successor_id  (successor_id)
#
# Foreign Keys
#
#  fk_rails_...  (successor_id => c14_labs.id)
#
class C14Lab < ApplicationRecord

  default_scope { order(active: :desc, name: :asc) }

  validates :name, presence: true
  validates :short_name, uniqueness: true, allow_nil: true

  # Use tree structure to denote lab succession (e.g. conventional to AMS)
  has_many :predecessors, class_name: "C14Lab", foreign_key: "successor_id"
  belongs_to :successor, class_name: "C14Lab", optional: true
  recursive_tree parent_key: :successor_id

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

  def location
    return nil if country_code.blank? and city.blank?
    [ city, country ].compact.join(", ")
  end

  def c14s_count
    c14s.count
  end

  def distinct_methods
    c14s.distinct(:method).pluck(:method)
  end

end
