# == Schema Information
#
# Table name: user_profiles
#
#  id         :bigint           not null, primary key
#  full_name  :string
#  orcid      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_user_profiles_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :user_profile do
    full_name { Faker::Name.name }
    orcid { '0000-0002-1825-0097' }
    user
  end
end
