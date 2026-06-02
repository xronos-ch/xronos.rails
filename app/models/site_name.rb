# == Schema Information
#
# Table name: site_names
#
#  id         :integer          not null, primary key
#  language   :string
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  site_id    :integer
#
# Indexes
#
#  index_site_names_on_site_id  (site_id)
#

class SiteName < ApplicationRecord
  belongs_to :site

  validates :name, presence: true

  include Versioned

end
