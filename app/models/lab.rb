class Lab < ApplicationRecord

  #validates :name, presence: true

  has_many :measurements, inverse_of: :lab

end
