# == Schema Information
#
# Table name: site_names
# Database name: primary
#
#  id         :bigint           not null, primary key
#  language   :string
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  site_id    :bigint
#
# Indexes
#
#  index_site_names_on_site_id  (site_id)
#
# Foreign Keys
#
#  fk_rails_...  (site_id => sites.id)
#
FactoryBot.define do
  factory :site_name do
    association :site
    sequence(:name) { |n| "Alternative site name #{n}" }
  end
end
