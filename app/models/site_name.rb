# == Schema Information
#
# Table name: site_names
# Database name: primary
#
#  id         :bigint           not null, primary key
#  language   :string
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  site_id    :bigint
#
# Indexes
#
#  index_site_names_on_site_id  (site_id)
#
# Foreign Keys
#
#  fk_rails_...  (site_id => sites.id)
#

class SiteName < ApplicationRecord
  include Peripheral

  belongs_to :site, touch: true

  validates :name, presence: true

  revision_comment_parent :site

  def self.label
    "site name"
  end

  def label
    name
  end
end
