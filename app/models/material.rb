# == Schema Information
#
# Table name: materials
# Database name: primary
#
#  id         :bigint           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_materials_on_name  (name)
#

class Material < ApplicationRecord
  default_scope { order(name: :asc) }

  include Versioned
  include Mergeable

  exact_duplicates_on :name

  has_many :samples, inverse_of: :material

  validates :name, presence: true

  after_save :merge_exact_duplicates
  validate :no_exact_duplicate, on: :create

  before_merge :reassign_samples!

  include PgSearch::Model
  pg_search_scope :search,
    against: :name,
    using: { tsearch: { prefix: true } } # match partial words

  acts_as_copy_target # enable CSV exports

  def self.label
    "material"
  end

  def label
    name
  end

  # Tidy up unused materials when samples are deleted
  def destroy_if_orphaned
    if samples.count == 0
      self.destroy
    end
  end

  private

  def reassign_samples!
    Sample.where(material_id: id).update_all(material_id: merged_into_id)
  end
end
