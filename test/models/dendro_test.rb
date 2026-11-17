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
end
