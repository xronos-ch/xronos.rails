class Reference < ApplicationRecord
  validates :bibtex, presence: true

  has_many :references_measurements
  has_many :measurements, through: :references_measurements
end
