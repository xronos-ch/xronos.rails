class FeatureType < ApplicationRecord

  validates :name, :description, presence: true

  has_many :on_site_object_positions, inverse_of: :feature_type

end
