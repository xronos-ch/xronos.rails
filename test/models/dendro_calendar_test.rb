require 'test_helper'

class DendroCalendarTest < ActiveSupport::TestCase
  test 'calendar overlap includes boundaries and ignores floating and empty series' do
    included = create(:dendro, :anchored, anchor_position: 2, anchor_year: 1,
                      measurements: [{ position: 1, value: nil }, { position: 4, value: 0.5 }])
    create(:dendro, :anchored, anchor_year: 10)
    create(:dendro, is_anchored: false)
    create(:dendro)
    create(:dendro, :anchored, measurements: [])

    assert_equal [included.id], Dendro.in_calendar_range(from_year: '0', to_year: '0').ids
    assert_equal [included.id], Dendro.in_calendar_range(from_year: '3', to_year: '3').ids
    assert_not_includes Dendro.in_calendar_range(to_year: '-1').ids, included.id
  end

  test 'one sided bounds and an absent range are supported' do
    earlier = create(:dendro, :anchored, anchor_year: -100)
    later = create(:dendro, :anchored, anchor_year: 100)
    floating = create(:dendro)

    assert_equal [earlier.id], Dendro.in_calendar_range(to_year: '0').ids
    assert_equal [later.id], Dendro.in_calendar_range(from_year: '0').ids
    assert_includes Dendro.in_calendar_range.ids, floating.id
  end
end
