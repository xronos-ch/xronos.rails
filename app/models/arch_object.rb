class ArchObject < ApplicationRecord
	has_many :samples, dependent: :destroy
  belongs_to :site
  belongs_to :material
  belongs_to :species
  belongs_to :on_site_object_position
  accepts_nested_attributes_for :samples
end
