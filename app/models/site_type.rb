class SiteType < ApplicationRecord
  has_many :sites, inverse_of: :site
end
