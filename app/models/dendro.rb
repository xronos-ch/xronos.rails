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
#  waney_edge         :boolean
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
  
  has_one :chron, as: :recordable
  belongs_to :sample
  accepts_nested_attributes_for :sample, reject_if: :all_blank
  
  has_many :citations, as: :citing
  has_many :references, :through => :citations

  delegate :context, to: :sample
  delegate :site, to: :sample
  
  validates_associated :sample
  
  belongs_to :chronology, optional: true
  
  include Versioned
  
  include HasIssues
  @issues = [ :missing_waney_edge_info, :missing_is_anchored_info, :missing_sample_elevation, :missing_object_info, :missing_wood_completeness_info, :unknown_chronology_type, :unknown_certainty ]
    
  def self.label
    "dendrochronological series"
  end

  def self.icon
    "icons/dendro.svg"
  end
  
  # Issues
  
  scope :missing_waney_edge_info, -> { where(waney_edge: nil) }
  def missing_waney_edge_info?
    waney_edge.nil?
  end
  
  scope :missing_is_anchored_info, -> { where(is_anchored: nil) }
  def missing_is_anchored_info?
    is_anchored.nil?
  end
  
  scope :missing_sample_elevation, -> { joins(:sample).where(samples: { position_z: nil }) }
  def missing_sample_elevation?
    sample.position_z.nil?
  end
  
  scope :missing_object_info, -> {
    where(object_title: nil)
      .or(where(object_type: nil))
      .or(where(object_description: nil))
  }
  def missing_object_info?
    object_title.nil? || object_type.nil? || object_description.nil?
  end
  
  scope :missing_wood_completeness_info, -> { where("wood_completeness = '{}'::jsonb") }
  def missing_wood_completeness_info?
    wood_completeness.blank? || wood_completeness == {}
  end
  
  scope :unknown_chronology_type, -> {
    left_outer_joins(:chronology)
      .where("dendros.chronology_id IS NULL OR chronologies.chronology_type IS NULL")
  }
  def unknown_chronology_type?
    chronology_id.blank? || chronology.blank? || chronology.chronology_type.nil?
  end
  
  scope :unknown_certainty, -> {
    left_outer_joins(:chronology)
      .where("dendros.chronology_id IS NULL OR chronologies.certainty IS NULL")
  }
  def unknown_certainty?
    chronology_id.blank? || chronology.blank? || chronology.certainty.nil?
  end
end
