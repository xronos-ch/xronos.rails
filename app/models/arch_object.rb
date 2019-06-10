class ArchObject < ApplicationRecord
	has_many :samples, dependent: :destroy
end
