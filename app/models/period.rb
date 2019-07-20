class Period < ApplicationRecord
  has_and_belongs_to_many :site_phases
end
