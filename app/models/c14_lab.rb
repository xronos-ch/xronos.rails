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

  include Versioned
  include Supersedable

  default_scope { order(active: :desc, name: :asc) }

  validates :name, presence: true

  has_many :c14s, inverse_of: :c14_lab

end
