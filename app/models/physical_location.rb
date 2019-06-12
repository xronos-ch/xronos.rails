class PhysicalLocation < ApplicationRecord
  belongs_to :site
  belongs_to :country
end

