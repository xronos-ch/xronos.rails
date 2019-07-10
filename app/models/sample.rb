class Sample < ApplicationRecord
  has_many :measurements, inverse_of: :sample
  accepts_nested_attributes_for :measurements, reject_if: :all_blank, allow_destroy: true
	belongs_to :arch_object
end
