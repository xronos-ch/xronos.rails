class Lab < ApplicationRecord
  has_many :measurements
  has_many :samples, :through => :measurements
end
