class ArchObject < ApplicationRecord
	has_many :samples, dependent: :destroy
  belongs_to :site
end
