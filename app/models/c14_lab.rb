# == Schema Information
#
# Table name: c14_labs
#
#  id            :bigint           not null, primary key
#  active        :boolean
#  name          :string
#  superseded_by :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_c14_labs_on_active         (active)
#  index_c14_labs_on_name           (name)
#  index_c14_labs_on_superseded_by  (superseded_by)
#
class C14Lab < ApplicationRecord

  default_scope { order(active: :desc, name: :asc) }

  validates :name, presence: true

  has_many :c14s, inverse_of: :c14_lab
  has_paper_trail

  acts_as_copy_target # enable CSV exports

  def self.label
    "radiocarbon lab"
  end

end
