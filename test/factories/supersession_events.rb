FactoryBot.define do
  factory :supersession_event do
    event_type    { 'supersede' }
    superseded    { create(:site) }
    superseded_by { create(:site) }
    comment       { nil }
  end

  factory :supersede_event, parent: :supersession_event, class: 'SupersessionEvent' do
    event_type { 'supersede' }
  end

  factory :restore_event, parent: :supersession_event, class: 'SupersessionEvent' do
    event_type { 'restore' }
  end
end
