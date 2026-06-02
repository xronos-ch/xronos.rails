# == Schema Information
#
# Table name: user_profiles
#
#  id           :integer          not null, primary key
#  user_id      :integer          not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  full_name    :string
#  orcid        :string
#  public_email :string
#  url          :string
#
# Indexes
#
#  index_user_profiles_on_user_id  (user_id)
#

FactoryBot.define do
  factory :user_profile do
    full_name { Faker::Name.name }
    orcid { '0000-0002-1825-0097' }
    public_email { Faker::Internet.email }
    url { Faker::Internet.url(host: "example.com") }
  end
end
