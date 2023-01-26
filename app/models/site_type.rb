# == Schema Information
#
# Table name: site_types
#
#  id            :bigint           not null, primary key
#  description   :text
#  name          :string
#  superseded_by :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_site_types_on_name           (name)
#  index_site_types_on_superseded_by  (superseded_by)
#
class SiteType < ApplicationRecord
  default_scope { order(name: :asc) }

  include Versioned
  include Supersedable

  include PgSearch::Model
  pg_search_scope :search,
    against: :name,
    using: { tsearch: { prefix: true } } # match partial words

  has_many :sites, inverse_of: :site_type

  validates :name, presence: true

end
