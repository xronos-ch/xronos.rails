# == Schema Information
#
# Table name: dendros
# Database name: primary
#
#  id                   :bigint           not null, primary key
#  anchor_position      :integer
#  anchor_year          :integer
#  death_year           :integer
#  description          :text
#  first_year           :integer
#  is_anchored          :boolean
#  last_year            :integer
#  measurement_unit     :string
#  measurement_variable :string
#  measurements         :jsonb            not null
#  name                 :string           not null
#  object_description   :text
#  object_dimensions    :jsonb
#  object_title         :string
#  object_type          :string
#  parameters           :jsonb
#  pith_year            :integer
#  project_end_date     :datetime
#  project_objective    :text
#  project_start_date   :datetime
#  project_title        :string
#  series_code          :string           not null
#  waney_edge           :boolean
#  wood_completeness    :jsonb
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  chronology_id        :bigint
#  sample_id            :bigint           not null
#
# Indexes
#
#  index_dendros_on_chronology_id  (chronology_id)
#  index_dendros_on_measurements   (measurements) USING gin
#  index_dendros_on_sample_id      (sample_id)
#  index_dendros_on_series_code    (series_code)
#
# Foreign Keys
#
#  fk_rails_...  (chronology_id => chronologies.id)
#  fk_rails_...  (sample_id => samples.id)
#
require "test_helper"

class DendroTest < ActiveSupport::TestCase
  test "a floating series keeps its positions and gaps when anchored" do
    measurements = [{ "position" => 184, "value" => 0 },
                    { "position" => 186, "value" => nil },
                    { "position" => 303, "value" => 0.42 }]
    dendro = create(:dendro, is_anchored: false, measurements: measurements)

    assert_equal [nil, nil, nil], dendro.series_points.pluck("calendar_year")

    dendro.update!(is_anchored: true, anchor_position: 184, anchor_year: -5258)

    assert_equal measurements, dendro.reload.measurements
    assert_equal [184, 303], dendro.position_range
    assert_equal [-5258, -5256, -5139], dendro.series_points.pluck("calendar_year")
    assert_equal [0, nil, 0.42], dendro.series_points.pluck("value")
  end

  test "an unknown or floating series cannot have a partial or implicit anchor" do
    dendro = build(:dendro)
    assert_nil dendro.is_anchored
    assert_predicate dendro, :valid?

    dendro.anchor_position = 1
    assert_not dendro.valid?
    assert dendro.errors[:anchor_position].present?

    dendro.is_anchored = true
    assert_not dendro.valid?
    assert dendro.errors[:anchor_year].present?

    dendro.anchor_year = 0
    assert_predicate dendro, :valid?
  end

  test "relational validation rejects duplicate positions" do
    dendro = build(:dendro, measurements: [{ position: 1, value: 0 }, { position: 1, value: nil }])

    assert_not dendro.valid?
    assert_includes dendro.errors[:measurements], "must have unique positions"
  end
  test 'ring widths reject negatives while preserving zero and missing values' do
    dendro = build(:dendro, measurement_variable: 'ring_width', measurement_unit: 'mm',
                   measurements: [{ position: 1, value: -0.5 }])

    assert_not dendro.valid?
    assert dendro.errors[:measurements].present?

    dendro.measurements = [{ position: 1, value: 0 }, { position: 2, value: nil }]
    assert_predicate dendro, :valid?
  end

  test "source codes can repeat without merging different or empty measurements" do
    original = create(:dendro, measurement_variable: "ring_width", measurement_unit: "mm")
    different = create(:dendro, sample: original.sample, series_code: original.series_code,
                       measurement_variable: "ring_width", measurement_unit: "mm",
                       measurements: [{ position: 1, value: 2.5 }])
    assert_not different.superseded?
    assert_equal original.series_code, different.series_code
    other_variable = create(:dendro, sample: original.sample, series_code: original.series_code,
                            measurement_variable: "earlywood_width", measurement_unit: "mm")
    assert_not other_variable.superseded?
    2.times { create(:dendro, sample: original.sample, series_code: original.series_code, measurements: []) }
    assert_equal 5, original.sample.dendros.count
    duplicate = build(:dendro, sample: original.sample, series_code: original.series_code,
                      measurement_variable: "ring_width", measurement_unit: "mm")
    assert_not duplicate.valid?
    assert_equal original, duplicate.find_exact_duplicate
  end

end
