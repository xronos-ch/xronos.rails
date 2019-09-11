class Country < ApplicationRecord

  validates :name, presence: true, uniqueness: true

  has_many :sites, inverse_of: :country

end
