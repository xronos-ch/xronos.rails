class Site < ApplicationRecord
  belongs_to :country
  belongs_to :site_type
end
