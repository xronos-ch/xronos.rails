class OnSiteObjectPosition < ApplicationRecord

  has_many :arch_objects, inverse_of: :on_site_object_position

  belongs_to :feature_type, optional: true
  validates_associated :feature_type

end
