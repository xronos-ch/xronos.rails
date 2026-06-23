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
  belongs_to :site, touch: true

  validates :name, presence: true

  before_save :set_revision_comment_on_save, if: :site
  before_destroy :set_revision_comment_on_destroy, if: :site

  def self.label
    "site name"
  end

  private

  def set_revision_comment_on_save
    site.revision_comment = new_record? ? "Added #{self.class.label}." : "Changed #{self.class.label}."
  end

  def set_revision_comment_on_destroy
    site.revision_comment = "Removed #{self.class.label}."
  end

end
