# == Schema Information
#
# Table name: site_types
# Database name: primary
#
#  id          :bigint           not null, primary key
#  description :text
#  name        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_site_types_on_name  (name)
#

class SiteType < ApplicationRecord
  include Peripheral

  default_scope { order(name: :asc) }

  include PgSearch::Model
  pg_search_scope :search,
    against: :name,
    using: { tsearch: { prefix: true } } # match partial words

  acts_as_copy_target # enable CSV exports

  has_and_belongs_to_many :sites

  validates :name, presence: true

  touch_referencing_records :sites

  def self.label
    "site type"
  end

  def label
    name
  end
end
