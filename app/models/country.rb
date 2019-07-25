class Country < ApplicationRecord
  has_many :sites, inverse_of: :site
  validates :name, :abbreviation, presence: true
end
