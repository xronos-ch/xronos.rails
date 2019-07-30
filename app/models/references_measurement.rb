class ReferencesMeasurement < ApplicationRecord
  belongs_to :reference
  belongs_to :measurement
  accepts_nested_attributes_for :reference, :reject_if => :all_blank
end
