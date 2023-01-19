# == Schema Information
#
# Table name: taxons
#
#  id         :bigint           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_taxons_on_name  (name)
#
class Taxon < ApplicationRecord
  default_scope { order(name: :asc) }

  include PgSearch::Model
  pg_search_scope :search, 
    against: :name, 
    using: { tsearch: { prefix: true } } # match partial words

  validates :name, presence: true

  has_many :samples

  has_paper_trail
end
