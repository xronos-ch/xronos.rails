# == Schema Information
#
# Table name: dendros
#
#  id                 :bigint           not null, primary key
#  anchor_position    :integer
#  anchor_year        :integer
#  measurement_unit   :string
#  measurement_variable :string
#  death_year         :integer
#  description        :text
#  first_year         :integer
#  is_anchored        :boolean
#  last_year          :integer
#  measurements       :jsonb            not null
#  name               :string           not null
#  object_description :text
#  object_dimensions  :jsonb
#  object_title       :string
#  object_type        :string
#  parameters         :jsonb
#  pith_year          :integer
#  project_end_date   :datetime
#  project_objective  :text
#  project_start_date :datetime
#  project_title      :string
#  series_code        :string           not null
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
class Dendro < Chron
  include Citable

  MEASUREMENT_VARIABLES = { "ring_width" => "Ring width", "earlywood_width" => "Earlywood width",
                            "latewood_width" => "Latewood width" }.freeze
  MEASUREMENT_UNITS = %w[mm µm].freeze
  EXPORT_COLUMNS = %i[id sample_id series_code name description is_anchored anchor_position anchor_year
                      measurement_variable measurement_unit waney_edge measurements created_at updated_at].freeze

  exact_duplicates_on :series_code, :sample_id

  accepts_nested_attributes_for :sample, reject_if: :all_blank
  belongs_to :chronology, optional: true

  validates_associated :sample
  validates :name, presence: true
  validates :series_code, presence: true, uniqueness: true
  normalizes :measurement_variable, :measurement_unit, with: ->(value) { value.presence }
  validates :measurement_variable, inclusion: { in: MEASUREMENT_VARIABLES.keys }, allow_blank: true
  validates :measurement_unit, inclusion: { in: MEASUREMENT_UNITS }, allow_blank: true
  validates :anchor_position, :anchor_year,
            numericality: { only_integer: true }, presence: true, if: :is_anchored?
  validates :anchor_position, :anchor_year, absence: true, unless: :is_anchored?
  validate :valid_measurements, if: :will_save_change_to_measurements?

  snapshot_peripherals :citations

  include PgSearch::Model
  pg_search_scope :search, against: [:name, :series_code], using: { tsearch: { prefix: true } }

  include HasIssues
  @issues = [ :missing_waney_edge_info, :missing_is_anchored_info, :missing_sample_elevation, :missing_object_info, :missing_wood_completeness_info, :unknown_chronology_type, :unknown_certainty ]

  def self.sort_series(relation, column, direction)
    direction = direction == "desc" ? :desc : :asc
    case column
    when "name", "is_anchored"
      relation.reorder(column => direction, id: :asc)
    when "calendar_start_year", "calendar_end_year"
      bound = column == "calendar_start_year" ? "MIN" : "MAX"
      year = <<~SQL.squish
        dendros.anchor_year::bigint - dendros.anchor_position +
          (SELECT #{bound}((point->>'position')::numeric)
           FROM jsonb_array_elements(dendros.measurements) AS point)
      SQL
      relation.reorder(Arel.sql("#{year} #{direction} NULLS LAST"), :id)
    else
      relation.reorder(:id)
    end
  end

  def self.label
    "dendrochronological series"
  end

  def self.icon
    "icons/dendro.svg"
  end

  def label
    name
  end

  def citation_title
    name
  end

  def calendar_year_at(position)
    return unless is_anchored? && anchor_year && anchor_position

    anchor_year + position - anchor_position
  end

  def position_range
    positions = measurements.map { |measurement| measurement.fetch("position") }
    positions.minmax if positions.any?
  end

  def calendar_start_year
    calendar_year_at(position_range.first) if position_range
  end

  def calendar_end_year
    calendar_year_at(position_range.last) if position_range
  end

  def series_points
    measurements.sort_by { |measurement| measurement.fetch("position") }.map do |measurement|
      measurement.merge("calendar_year" => calendar_year_at(measurement.fetch("position")))
    end
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

  scope :missing_wood_completeness_info, -> { where(wood_completeness: nil).or(where("wood_completeness = '{}'::jsonb")) }
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

  private

  def valid_measurements
    unless measurements.is_a?(Array) && measurements.all? { |entry| valid_measurement?(entry) }
      errors.add(:measurements, "must contain an integer position and a finite nonnegative numeric or missing value for each entry")
      return
    end

    positions = measurements.map { |entry| entry.stringify_keys.fetch("position") }
    errors.add(:measurements, "must have unique positions") if positions.uniq.size != positions.size
  end

  def valid_measurement?(entry)
    return false unless entry.is_a?(Hash)

    point = entry.stringify_keys
    value = point["value"]
    point["position"].is_a?(Integer) && point.key?("value") &&
      (value.nil? || (value.is_a?(Numeric) && value.finite? && value >= 0))
  end
end
