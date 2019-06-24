class ArchObject < ApplicationRecord
	has_many :samples, dependent: :destroy
  belongs_to :site
  belongs_to :material
  belongs_to :species
end
