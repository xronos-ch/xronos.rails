class Site < ApplicationRecord
  has_many :arch_objects, inverse_of: :site
  belongs_to :country
  accepts_nested_attributes_for :country, reject_if: :all_blank, allow_destroy: true
  belongs_to :site_type
  accepts_nested_attributes_for :site_type, reject_if: :all_blank, allow_destroy: true
end
