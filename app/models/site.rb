class Site < ApplicationRecord
  has_many :arch_objects, inverse_of: :site
  belongs_to :country, optional: true
  accepts_nested_attributes_for :country, reject_if: :all_blank, allow_destroy: true
  belongs_to :site_type, optional: true
  accepts_nested_attributes_for :site_type, reject_if: :all_blank, allow_destroy: true
end
