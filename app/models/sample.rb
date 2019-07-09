class Sample < ApplicationRecord
	belongs_to :arch_object
  has_many :measurements
  accepts_nested_attributes_for :measurements
end
