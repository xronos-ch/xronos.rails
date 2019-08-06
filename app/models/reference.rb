class Reference < ApplicationRecord
  validates :short_ref, presence: true

  has_many :references_measurements, :dependent => :destroy
  has_many :measurements, through: :references_measurements
end
