require 'test_helper'

class SupersessionEventTest < ActiveSupport::TestCase
  test 'has a valid factory' do
    assert FactoryBot.create(:supersession_event).persisted?
  end

  test 'validates event_type is included in EVENT_TYPES' do
    event = build(:supersession_event, event_type: 'bogus')
    assert_not event.valid?
    assert event.errors[:event_type].any?
  end

  test "accepts 'supersede' as an event_type" do
    event = build(:supersede_event)
    assert event.valid?
  end

  test "accepts 'restore' as an event_type" do
    event = build(:restore_event)
    assert event.valid?
  end

  test 'rejects self-supersession' do
    site = create(:site)
    event = build(:supersession_event, superseded: site, superseded_by: site)
    assert_not event.valid?
    assert event.errors[:superseded_by].any?
  end

  test 'is append-only: cannot be updated' do
    event = create(:supersession_event)
    event.comment = 'changed'
    assert_raises(ActiveRecord::ReadOnlyRecord) { event.save! }
  end

  test 'is append-only: cannot be destroyed' do
    event = create(:supersession_event)
    assert_raises(ActiveRecord::ReadOnlyRecord) { event.destroy! }
  end
end
