# == Schema Information
#
# Table name: supersession_events
# Database name: primary
#
#  id                 :bigint           not null, primary key
#  comment            :text
#  event_type         :string           not null
#  superseded_by_type :string           not null
#  superseded_type    :string           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  superseded_by_id   :bigint           not null
#  superseded_id      :bigint           not null
#
# Indexes
#
#  index_supersession_events_on_event_type     (event_type,created_at)
#  index_supersession_events_on_superseded     (superseded_type,superseded_id,created_at)
#  index_supersession_events_on_superseded_by  (superseded_by_type,superseded_by_id,created_at)
#
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
