require 'test_helper'

class SupersessionTest < ActiveSupport::TestCase
  test 'has a valid factory' do
    assert FactoryBot.create(:supersession).persisted?
  end

  test 'has a unique index on superseded_type and superseded_id' do
    canonical = create(:site)
    a = create(:site)
    b = create(:site)
    create(:supersession, superseded: a, superseded_by: canonical)

    assert_raises(ActiveRecord::RecordNotUnique) do
      create(:supersession, superseded: a, superseded_by: b)
    end
  end

  test 'rebuild_from_events! wipes the cache and rebuilds it from the event log' do
    canonical = create(:site)
    superseded = create(:site, :superseded_by, canonical: canonical)
    create(:supersede_event, superseded: superseded, superseded_by: canonical)

    # Sanity-check: cache has 1 row, event log has 1 row.
    assert_equal 1, Supersession.count
    assert_equal 1, SupersessionEvent.count

    Supersession.rebuild_from_events!

    assert_equal 1, Supersession.count
    assert_equal superseded, Supersession.find_by(superseded: superseded)&.superseded
    assert_equal canonical, Supersession.find_by(superseded: superseded)&.superseded_by
  end

  test 'rebuild_from_events! drops rows that have a later restore event' do
    canonical = create(:site)
    site = create(:site)
    site.supersede!(canonical, 'merge')
    site.restore!

    Supersession.rebuild_from_events!

    assert_equal 0, Supersession.count
  end

  test 'rebuild_from_events! is idempotent' do
    canonical = create(:site)
    superseded = create(:site, :superseded_by, canonical: canonical)
    create(:supersede_event, superseded: superseded, superseded_by: canonical)

    Supersession.rebuild_from_events!
    first_state = Supersession.pluck(:superseded_id, :superseded_by_id).sort

    Supersession.rebuild_from_events!
    second_state = Supersession.pluck(:superseded_id, :superseded_by_id).sort

    assert_equal first_state, second_state
  end
end
