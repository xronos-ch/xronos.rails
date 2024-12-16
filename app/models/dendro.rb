# == Schema Information
#
# Table name: dendros
#
#  id                 :bigint           not null, primary key
#  death_year         :integer
#  description        :text
#  end_year           :integer
#  first_year         :integer
#  is_anchored        :boolean          default(FALSE)
#  last_year          :integer
#  measurements       :jsonb            not null
#  name               :string           not null
#  object_description :text
#  object_dimensions  :jsonb
#  object_title       :string
#  object_type        :string
#  offset             :integer
#  parameters         :jsonb
#  pith_year          :integer
#  project_end_date   :datetime
#  project_objective  :text
#  project_start_date :datetime
#  project_title      :string
#  series_code        :string           not null
#  start_year         :integer
#  wood_completeness  :jsonb
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  chronology_id      :bigint
#  sample_id          :bigint           not null
#
# Indexes
#
#  index_dendros_on_chronology_id  (chronology_id)
#  index_dendros_on_measurements   (measurements) USING gin
#  index_dendros_on_sample_id      (sample_id)
#  index_dendros_on_series_code    (series_code) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (chronology_id => chronologies.id)
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
