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
#  whodunnit_user_id  :bigint           not null
#
# Indexes
#
#  index_supersession_events_on_event_type         (event_type,created_at)
#  index_supersession_events_on_superseded         (superseded_type,superseded_id,created_at)
#  index_supersession_events_on_superseded_by      (superseded_by_type,superseded_by_id,created_at)
#  index_supersession_events_on_whodunnit_user_id  (whodunnit_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (whodunnit_user_id => users.id)
#
FactoryBot.define do
  factory :supersession_event do
    event_type      { 'supersede' }
    superseded      { create(:site) }
    superseded_by   { create(:site) }
    whodunnit_user  { create(:user) }
    comment         { nil }
  end

  factory :supersede_event, parent: :supersession_event, class: 'SupersessionEvent' do
    event_type { 'supersede' }
  end

  factory :restore_event, parent: :supersession_event, class: 'SupersessionEvent' do
    event_type { 'restore' }
  end
end
