# == Schema Information
#
# Table name: dendros
#
#  id           :bigint           not null, primary key
#  description  :text
#  end_year     :integer
#  is_anchored  :boolean          default(FALSE)
#  measurements :jsonb            not null
#  name         :string           not null
#  offset       :integer
#  series_code  :string           not null
#  start_year   :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  sample_id    :bigint           not null
#
# Indexes
#
#  index_dendros_on_measurements  (measurements) USING gin
#  index_dendros_on_sample_id     (sample_id)
#  index_dendros_on_series_code   (series_code) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (sample_id => samples.id)
#
class Dendro < ApplicationRecord
  belongs_to :sample
  accepts_nested_attributes_for :sample, reject_if: :all_blank
  
  has_many :citations, as: :citing
  has_many :references, :through => :citations

  delegate :context, to: :sample
  delegate :site, to: :sample
  
  validates_associated :sample
  
  include Versioned
    
  def self.label
    "dendrochronological series"
  end

  def self.icon
    "icons/dendro.svg"
  end
end
