class OnSiteObjectPosition < ApplicationRecord

  has_many :arch_objects, inverse_of: :on_site_object_position

  belongs_to :feature_type, optional: true
  accepts_nested_attributes_for :feature_type, reject_if: :all_blank
  validates_associated :feature_type

end
