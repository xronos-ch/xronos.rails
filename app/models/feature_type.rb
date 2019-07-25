class FeatureType < ApplicationRecord
  validates :name, :description, presence: true
end
