class C14Lab < ApplicationRecord
  default_scope { order(active: :desc, name: :asc) }

  validates :name, presence: true

  has_many :c14s, inverse_of: :c14_lab

  acts_as_copy_target # enable CSV exports
end
