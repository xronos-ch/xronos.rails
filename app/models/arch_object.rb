class ArchObject < ApplicationRecord
	has_many :samples, inverse_of: :arch_object
  accepts_nested_attributes_for :samples, reject_if: :all_blank, allow_destroy: true
  belongs_to :site
  belongs_to :material
  belongs_to :species
  belongs_to :on_site_object_position
end
