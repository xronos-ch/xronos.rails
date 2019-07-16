class ArchObject < ApplicationRecord
	has_many :samples, inverse_of: :arch_object
  accepts_nested_attributes_for :samples, reject_if: :all_blank, allow_destroy: true
  belongs_to :site, optional: true
  accepts_nested_attributes_for :site, reject_if: :all_blank
  belongs_to :material, optional: true
  accepts_nested_attributes_for :material, reject_if: :all_blank
  belongs_to :species, optional: true
  accepts_nested_attributes_for :species, reject_if: :all_blank
  belongs_to :on_site_object_position, optional: true
  accepts_nested_attributes_for :on_site_object_position, reject_if: :all_blank
end
