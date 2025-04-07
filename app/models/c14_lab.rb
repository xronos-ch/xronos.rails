# == Schema Information
#
# Table name: c14_labs
#
#  id         :bigint           not null, primary key
#  active     :boolean
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
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

  def self.label
    "radiocarbon lab"
  end

  def country
    "an unknown land" # TODO
  end

  def lab_code
    # TODO: There can only be one...
    c14_lab_codes.select(canonical: true).first.lab_code
  end

  def c14s_count
    c14s.count
  end

end
