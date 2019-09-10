class SourceDatabase < ApplicationRecord

  validates :name, presence: true

  has_many :c14_measurements, inverse_of: :source_database

end
