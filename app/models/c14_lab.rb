class C14Lab < ApplicationRecord

  default_scope { order(active: :desc, name: :asc) }

  validates :name, presence: true

  has_many :c14s, inverse_of: :c14_lab
  has_paper_trail

end
