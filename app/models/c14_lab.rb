class C14Lab < ApplicationRecord

  validates :name, presence: true

  has_many :c14s, inverse_of: :c14_lab

end
